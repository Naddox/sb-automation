--- if you're overwriting this in the implementing object, you MUST add 'datawire.createConnectionTable()' to your function
function onNodeConnectionChange()
  --world.logInfo("in onNodeConnectionChange()")
  datawire.createConnectionTable()
end

datawire = {}

--- this should be called by the implementing object in its own init()
function datawire.init()
  datawire.createConnectionTable()
end

--- Creates connection tables for inbound and outbound nodes
function datawire.createConnectionTable()
  storage.outboundConnections = {}
  local i = 0
  while i < entity.outboundNodeCount() do
    storage.outboundConnections[i] = entity.getOutboundNodeIds(i)
    i = i + 1
  end

  storage.inboundConnections = {}
  local entityIds
  i = 0
  while i < entity.inboundNodeCount() do
    entityIds = entity.getInboundNodeIds(i)
    for j, entityId in ipairs(entityIds) do
      storage.inboundConnections[entityId] = i
    end
    i = i + 1
  end

  world.logInfo(string.format("%s (id %d) finished building tables for %d outbound and %d inbound nodes", entity.configParameter("objectName"), entity.id(), entity.outboundNodeCount(), entity.inboundNodeCount()))
  world.logInfo(storage.outboundConnections)
  world.logInfo(storage.inboundConnections)
end

--- Sends data to another datawire object
-- @param data the data to be sent
-- @param dataType the data type to be sent ("boolean", "number", "string", "area", etc.)
-- @param nodeId the outbound node id to send to, or "all" for all outbound nodes
-- @returns true if at least one object successfully received the data
function datawire.sendData(data, dataType, nodeId)
  local transmitSuccess = false

  if nodeId == "all" then
    for k, v in pairs(storage.outboundConnections) do
      transmitSuccess = datawire.sendData(data, dataType, k) or transmitSuccess
    end
  else
    if storage.outboundConnections[nodeId] and #storage.outboundConnections[nodeId] > 0 then 
      for i, entityId in ipairs(storage.outboundConnections[nodeId]) do
        if entityId ~= entity.id() then
          transmitSuccess = world.callScriptedEntity(entityId, "datawire.receiveData", { data, dataType, entity.id() }) or transmitSuccess
        end
      end
    end
  end

  -- if not transmitSuccess then
  --   world.logInfo(string.format("DataWire: %s (id %d) FAILED to send data of type %s", entity.configParameter("objectName"), entity.id(), dataType))
  --   world.logInfo(data)
  -- end

  return transmitSuccess
end

--- Receives data from another datawire object
-- @param data the data received
-- @param dataType the data type received ("boolean", "number", "string", "area", etc.)
-- @param sourceEntityId the id of the sending entity, which can be use for an imperfect node association
-- @returns true if valid data was received
function datawire.receiveData(args)
  --unpack args
  local data = args[1]
  local dataType = args[2]
  local sourceEntityId = args[3]

  --convert entityId to nodeId
  local nodeId = storage.inboundConnections[sourceEntityId]

  if nodeId ~= nil and validateData(data, dataType, nodeId) then
    onValidDataReceived(data, dataType, nodeId)

    --world.logInfo(string.format("DataWire: %s received data of type %s from %d", entity.configParameter("objectName"), dataType, sourceEntityId))
    --world.logInfo(data)

    return true
  else
    world.logInfo(string.format("DataWire: %s received INVALID data of type %s from %d", entity.configParameter("objectName"), dataType, sourceEntityId))
    world.logInfo(data)

    return false
  end
end

--- Validates data received from another datawire object
-- @param data the data to be validated
-- @param dataType the data type to be validated ("boolean", "number", "string", "area", etc.)
-- @param nodeId the inbound node id on which data was received
-- @returns true if the data is valid
function validateData(data, dataType, nodeId)
  --to be implemented by object
  return true
end

--- Hook for datawire objects to use received data
-- @param data the data
-- @param dataType the data type ("boolean", "number", "string", "area", etc.)
-- @param nodeId the inbound node id on which data was received
function onValidDataReceived(data, dataType, nodeId)
  --to be implemented by object
end
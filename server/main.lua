-------------------------------------------------
-- 
-- COMMANDS
-- 
-------------------------------------------------
lib.addCommand(IR8.Config.Commands.Tickets, {
    help = IR8.Config.Commands.TicketsDescription,
    params = {}
}, function(source, args, raw)
    local hasAdminPermission = IR8.Utilities.HasPermission(IR8.Config.AdminPermissions, IR8.Bridge.GetPlayerPermission(source))
    TriggerClientEvent(IR8.Config.ClientCallbackPrefix .. "ShowNUI", source, hasAdminPermission)
end)

-------------------------------------------------
-- 
-- NOTIFICATIONS
-- 
-------------------------------------------------
function SendNotificationIfOnline (identifier, title, notification, type)
    local src = IR8.Bridge.GetPlayerSourceIfOnlineByIdentifier(identifier)

    if src then
        IR8.Utilities.NotifyFromServer(src, "ticket_manager", title, notification, type)
    end
end


-------------------------------------------------
-- 
-- CALL BACKS
-- 
-------------------------------------------------

-- Return admin privs (bool)
lib.callback.register(IR8.Config.ServerCallbackPrefix .. "HasAdminPermissions", function (src)
    return IR8.Utilities.HasPermission(IR8.Config.AdminPermissions, IR8.Bridge.GetPlayerPermission(src))
end)

-- Load all tickets
lib.callback.register(IR8.Config.ServerCallbackPrefix .. "Tickets_Load", function (src)
    IR8.Utilities.DebugPrint('[EVENT] ' .. IR8.Bridge.GetPlayerIdentifier(src) .. ' loaded ticket list data.')

    -- Check if user has permissions and get their identifier
    local hasAdminPermission = IR8.Utilities.HasPermission(IR8.Config.AdminPermissions, IR8.Bridge.GetPlayerPermission(source))
    local identifier = IR8.Bridge.GetPlayerIdentifier(src)

    -- Pull tickets based on privelage
    return IR8.Database.GetTickets(hasAdminPermission, identifier)
end)

-- Load ticket data
lib.callback.register(IR8.Config.ServerCallbackPrefix .. "Ticket_Load", function (src, data)
    IR8.Utilities.DebugPrint('[EVENT] ' .. IR8.Bridge.GetPlayerIdentifier(src) .. ' loaded ticket data for ticket id: ' .. data.id .. '.')

    -- Get ticket data from database
    return IR8.Database.GetTicket(data.id)
end)

-- Update ticket status
lib.callback.register(IR8.Config.ServerCallbackPrefix .. "Ticket_UpdateStatus", function (src, data)
    IR8.Utilities.DebugPrint('[EVENT] ' .. IR8.Bridge.GetPlayerIdentifier(src) .. ' updated ticket status for id: ' .. data.id .. ' to ' .. data.status)

    local res = IR8.Database.UpdateTicketStatus(data.id, data.status)

    if res.success then
        local ticketData = IR8.Database.GetTicket(data.id)
        if ticketData then
            SendNotificationIfOnline(ticketData.identifier, "Ticket Status", "Your ticket status has been updated to " .. data.status .. ".")
        end
    end

    -- Get ticket data from database
    return res
end)

-- For creating a ticket
lib.callback.register(IR8.Config.ServerCallbackPrefix .. "Ticket_CreateReply", function (src, data)
    local identifier = IR8.Bridge.GetPlayerIdentifier(src)
    local name = IR8.Bridge.GetPlayerName(src)
    local res = IR8.Database.CreateReply(identifier, name, data)

    if res.success then 
        local ticketData = IR8.Database.GetTicket(data.ticket_id)
        if ticketData then
            SendNotificationIfOnline(ticketData.identifier, "Ticket Reply", "You have received a reply on a ticket you created.")
        end
    end

    return res
end)

-- For creating a ticket
lib.callback.register(IR8.Config.ServerCallbackPrefix .. "Ticket_Create", function (src, data)
    local identifier = IR8.Bridge.GetPlayerIdentifier(src)
    local name = IR8.Bridge.GetPlayerName(src)
    local res = IR8.Database.CreateTicket(identifier, name, data)

    if res.success then 

        -- Send discord webhook
        IR8.Utilities.DebugPrint("Sending discord notification for created ticket.")
        IR8.Utilities.SendDiscordEmbed({
            title = "Ticket Created",
            message = "A ticket was created with title: " .. data.title
        })
    end

    return res
end)
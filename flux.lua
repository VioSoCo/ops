    dofile("utils.lua")

    local gui = require("sgui")
    local component = require("component")

    local flux = component.isAvailable("flux_controller") and component.flux_controller or nil

    local maxEnergyFluxNetworkInput = 0;

    fluxUI = { id = 'fluxFrame' }
    fluxUI.update = function()
        local frameBox = frameBoxes[fluxUI.id]
        local posX, posY = frameBox.x, frameBox.y + 1

        if flux ~= nil then
            local fluxInfo = flux.getNetworkInfo()
            local fluxEnergy = flux.getEnergyInfo()
            gui.text(posX, posY, "&aСеть:&e " .. fluxInfo.name)
        
            gui.text(posX, posY + 1, string.rep(" ", 20))
            gui.text(posX, posY + 1, "&aВход: &2 " .. energy(fluxEnergy.energyInput/4) )
        
            gui.text(posX, posY + 2, string.rep(" ", 20))
            gui.text(posX, posY + 2, "&aБуфер:&2 " .. string.sub(energy(fluxEnergy.totalBuffer), 1, -3))
            if maxEnergyFluxNetworkInput < fluxEnergy.energyInput then
                maxEnergyFluxNetworkInput = fluxEnergy.energyInput
            end
            gui.text(posX, posY + 3, "&aМаксимальный вход:&2 " .. energy(maxEnergyFluxNetworkInput/4))
        else
            gui.text(posX, posY, "&aНет подключенной FLux сети(")
        end
    end

    fluxUI.renderMain = function(fr, fc)
        return {
            fr = fr,
            fc = fc,
            title = "Энерго-сеть",
            color = gui.colors["border"],
            id = fluxUI.id
        }
    end
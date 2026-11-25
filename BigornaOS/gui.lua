-- BigornaOS - GUI mínima de teste (/BigornaOS/gui.lua)
-- Versão de teste: mostra um cabeçalho e espera uma tecla para não fechar o ecrã.

local gpu = component.gpu
local largura, altura = gpu.getResolution()

gpu.setBackground(0x1E3A5F)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, largura, 1, " ")
gpu.set(2, 1, "BigornaOS")

gpu.setBackground(0x000000)
gpu.fill(1, 2, largura, altura - 1, " ")
gpu.set(2, 4, "Sistema arrancado com sucesso.")
gpu.set(2, 6, "Prime qualquer tecla para continuar.")

-- Espera por uma tecla antes de terminar
while true do
  local sinal = computer.pullSignal()
  if sinal == "key_down" then break end
end

gpu.setBackground(0x000000)
gpu.fill(1, 1, largura, altura, " ")

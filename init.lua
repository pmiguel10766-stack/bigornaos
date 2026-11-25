-- BigornaOS - init.lua
-- Chamado pelo núcleo (/boot/core.lua). Mostra o carregador e depois arranca a GUI.
-- Os ficheiros são lidos do disco de arranque, pelo mesmo método que o núcleo usa.

local disco = component.proxy(computer.getBootAddress())

local function ler_ficheiro(caminho)
  local f, erro = disco.open(caminho, "r")
  if not f then
    error("não foi possível abrir " .. caminho .. ": " .. tostring(erro), 0)
  end
  local partes = {}
  while true do
    local bloco = disco.read(f, math.huge)
    if not bloco then break end
    partes[#partes + 1] = bloco
  end
  disco.close(f)
  return table.concat(partes)
end

-- Compila e executa um ficheiro do disco de arranque
local function executar(caminho)
  local codigo = ler_ficheiro(caminho)
  local funcao, erro = load(codigo, "=" .. caminho, "t", _G)
  if not funcao then
    error("erro de sintaxe em " .. caminho .. ": " .. tostring(erro), 0)
  end
  return funcao()
end

-- 1. Carregador (tela de arranque com o nome BigornaOS)
local ok, erro = pcall(executar, "/boot/carregador.lua")
if not ok then
  -- Se o carregador falhar, o sistema continua em vez de parar
  computer.beep()
end

-- 2. Interface gráfica
executar("/BigornaOS/gui.lua")

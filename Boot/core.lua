-- BigornaOS - núcleo (/boot/core.lua)
-- Carregado pelo EEPROM. Lê /init.lua do disco de arranque e passa-lhe o controlo.
-- Não usa require: o EEPROM corre sem OpenOS, por isso usa apenas as globais
-- 'component' e 'computer' e as funções básicas do Lua.

local bootaddr = computer.getBootAddress()
local disco = component.proxy(bootaddr)

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

local codigo = ler_ficheiro("/init.lua")
local funcao, erro = load(codigo, "=init.lua", "t", _G)
if not funcao then
  error("erro de sintaxe em init.lua: " .. tostring(erro), 0)
end

return funcao()

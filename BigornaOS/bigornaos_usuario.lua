-- BigornaOS - configuração do utilizador (/BigornaOS/usuario.lua)
--
-- Guarda as preferências em /BigornaOS/config.txt, uma por linha (chave=valor).
-- Expõe a tabela global BigornaOS_usuario para outros ficheiros do sistema:
--   BigornaOS_usuario.config.nome          -> nome do utilizador
--   BigornaOS_usuario.config.fundo         -> nome do fundo escolhido
--   BigornaOS_usuario.definir(chave, valor) -> altera e guarda uma preferência

local disco = component.proxy(computer.getBootAddress())
local CAMINHO = "/BigornaOS/config.txt"

local config = {
  nome = "Utilizador",
  fundo = "azul",
}

local function carregar()
  if not disco.exists(CAMINHO) then return end
  local f = disco.open(CAMINHO, "r")
  if not f then return end
  local partes = {}
  while true do
    local bloco = disco.read(f, math.huge)
    if not bloco then break end
    partes[#partes + 1] = bloco
  end
  disco.close(f)

  for chave, valor in table.concat(partes):gmatch("(%w+)=([^\n]*)") do
    config[chave] = valor
  end
end

local function guardar()
  local linhas = {}
  for chave, valor in pairs(config) do
    linhas[#linhas + 1] = chave .. "=" .. tostring(valor)
  end
  local f = disco.open(CAMINHO, "w")
  if not f then return false end
  disco.write(f, table.concat(linhas, "\n"))
  disco.close(f)
  return true
end

local function definir(chave, valor)
  config[chave] = valor
  return guardar()
end

carregar()

BigornaOS_usuario = {
  config = config,
  definir = definir,
  guardar = guardar,
}

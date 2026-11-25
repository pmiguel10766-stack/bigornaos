-- BigornaOS - fundo do ecrã (/BigornaOS/fundo.lua)
--
-- Aplica o fundo guardado na configuração do utilizador (ver usuario.lua).
-- Expõe a tabela global BigornaOS_fundo:
--   BigornaOS_fundo.aplicar("verde") -> muda o fundo e guarda a escolha

local gpu = component.gpu

local FUNDOS = {
  azul   = 0x1E3A5F,
  cinza  = 0x2B2B2B,
  verde  = 0x1F4D2B,
  preto  = 0x000000,
}

local function pintar(nome)
  local cor = FUNDOS[nome] or FUNDOS.azul
  local largura, altura = gpu.getResolution()
  gpu.setBackground(cor)
  gpu.fill(1, 1, largura, altura, " ")
  return nome
end

local function aplicar(nome)
  if not FUNDOS[nome] then
    return false, "fundo desconhecido: " .. tostring(nome)
  end
  pintar(nome)
  if BigornaOS_usuario then
    BigornaOS_usuario.definir("fundo", nome)
  end
  return true
end

-- Ao carregar o ficheiro, aplica o fundo guardado (ou o azul por omissão)
local escolhido = "azul"
if BigornaOS_usuario and BigornaOS_usuario.config.fundo then
  escolhido = BigornaOS_usuario.config.fundo
end
pintar(escolhido)

BigornaOS_fundo = {
  aplicar = aplicar,
  disponiveis = FUNDOS,
}

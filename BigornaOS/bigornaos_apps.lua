-- BigornaOS - lançador de aplicações (/BigornaOS/apps.lua)
--
-- Lista os ficheiros .lua da pasta /BigornaOS/apps/ e executa o que o utilizador escolher.
--
-- Como criar uma app:
--   1. Cria um ficheiro em /BigornaOS/apps/, por exemplo /BigornaOS/apps/notas.lua
--   2. Escreve o código normal de Lua. Usa 'component' e 'computer' como globais.
--   3. Ao terminar, a app devolve o controlo ao lançador.
--
-- Teclas: 1 a 9 para escolher uma app, Q para voltar ao sistema.

local gpu = component.gpu
local disco = component.proxy(computer.getBootAddress())
local PASTA = "/BigornaOS/apps/"

local function ler_ficheiro(caminho)
  local f, erro = disco.open(caminho, "r")
  if not f then
    return nil, "não foi possível abrir " .. caminho .. ": " .. tostring(erro)
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

local function listar_apps()
  local lista = {}
  if not disco.exists(PASTA) then return lista end
  for _, nome in ipairs(disco.list(PASTA)) do
    if nome:match("%.lua$") then
      table.insert(lista, nome)
    end
  end
  table.sort(lista)
  return lista
end

local function executar_app(nome)
  local codigo, erro = ler_ficheiro(PASTA .. nome)
  if not codigo then
    return erro
  end
  local funcao, erro_sintaxe = load(codigo, "=" .. nome, "t", _G)
  if not funcao then
    return "erro de sintaxe em " .. nome .. ": " .. tostring(erro_sintaxe)
  end
  local ok, erro_execucao = pcall(funcao)
  if not ok then
    return "erro em " .. nome .. ": " .. tostring(erro_execucao)
  end
  return nil
end

local function desenhar(apps, mensagem)
  local largura, altura = gpu.getResolution()
  gpu.setBackground(0x1E3A5F)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, largura, 1, " ")
  gpu.set(2, 1, "BigornaOS - Aplicações")

  gpu.setBackground(0x000000)
  gpu.fill(1, 2, largura, altura - 1, " ")

  if #apps == 0 then
    gpu.set(2, 4, "Não há aplicações instaladas em " .. PASTA)
    gpu.set(2, 5, "Cria um ficheiro .lua nessa pasta para começar.")
  else
    gpu.set(2, 4, "Escolhe uma aplicação:")
    for i, nome in ipairs(apps) do
      gpu.set(4, 5 + i, i .. " - " .. nome:gsub("%.lua$", ""))
    end
  end

  gpu.set(2, altura - 1, "Q - voltar")
  if mensagem then
    gpu.set(2, altura, mensagem .. string.rep(" ", largura))
  end
end

local function main()
  local mensagem = nil
  while true do
    local apps = listar_apps()
    desenhar(apps, mensagem)
    mensagem = nil

    local sinal, _, caracter = computer.pullSignal()
    if sinal == "key_down" and caracter then
      local tecla = string.char(caracter):lower()
      if tecla == "q" then
        return
      end
      local n = tonumber(tecla)
      if n and apps[n] then
        local erro = executar_app(apps[n])
        mensagem = erro or ("Voltaste de " .. apps[n])
      end
    end
  end
end

main()

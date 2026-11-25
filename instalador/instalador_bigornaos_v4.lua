-- BigornaOS - instalador por etapas, v2 (modo texto, sem modo automático)
-- Requer: HDD, placa de rede (internet card) e OpenOS para correr este script.
-- Substitui BASE_URL pelo endereço real antes de usar.

local component = require("component")
local computer = require("computer")
local term = require("term")

local BASE_URL = "https://raw.githubusercontent.com/pmiguel10766-stack/bigornaos/main/" -- repositório oficial do BigornaOS

local ETAPAS = {
  boot = {
    descricao = "Núcleo sistema",
    ficheiros = { { url = "boot/core.lua", dest = "/boot/core.lua" } },
  },
  carregador = {
    descricao = "Tela carregador",
    ficheiros = { { url = "boot/carregador.lua", dest = "/boot/carregador.lua" } },
  },
  init = {
    descricao = "init.lua",
    ficheiros = { { url = "init.lua", dest = "/init.lua" } },
  },
  app = {
    descricao = "Apps",
    ficheiros = { { url = "BigornaOS/apps.lua", dest = "/BigornaOS/apps.lua" } },
  },
  gui = {
    descricao = "GUI",
    ficheiros = { { url = "BigornaOS/gui.lua", dest = "/BigornaOS/gui.lua" } },
  },
  usuario = {
    descricao = "Configuração Usuário",
    ficheiros = { { url = "BigornaOS/usuario.lua", dest = "/BigornaOS/usuario.lua" } },
  },
  fundo = {
    descricao = "Fundo Tela",
    ficheiros = { { url = "BigornaOS/fundo.lua", dest = "/BigornaOS/fundo.lua" } },
  },
}

local ORDEM = { "boot", "carregador", "init", "app", "gui", "usuario", "fundo" }

local disco_escolhido = nil -- { endereco, disco }

local function listar_discos()
  local lista = {}
  local arranque = computer.getBootAddress()
  for endereco in component.list("filesystem") do
    local disco = component.proxy(endereco)
    if endereco ~= arranque and not disco.isReadOnly() then
      table.insert(lista, { endereco = endereco, disco = disco })
    end
  end
  return lista
end

local function desenhar_barra(atual, total, nome, y)
  local largura = 20
  local pct = total > 0 and math.floor(atual / total * 100) or 100
  local cheios = math.floor(pct / 100 * largura)
  local linha = string.format("[%s%s] %3d%% %s",
    string.rep("#", cheios), string.rep(" ", largura - cheios), pct, nome)
  term.setCursor(1, y)
  term.write(linha .. string.rep(" ", 10))
end

local function buscar_conteudo(url)
  if not component.isAvailable("internet") then
    return false, "placa de rede não encontrada"
  end
  local ok, conteudo = pcall(function()
    local pedido = component.internet.request(BASE_URL .. url)
    while not pedido.finishConnect() do
      computer.pullSignal(0.2)
    end
    local partes = {}
    for pedaco in pedido do
      table.insert(partes, pedaco)
    end
    return table.concat(partes)
  end)
  if not ok then
    return false, tostring(conteudo)
  end
  return true, conteudo
end

local function gravar(disco, destino, conteudo)
  local pasta = destino:match("^(.*)/[^/]+$")
  if pasta and pasta ~= "" and not disco.exists(pasta) then
    disco.makeDirectory(pasta)
  end
  local f = disco.open(destino, "w")
  if not f then
    return false, "não foi possível criar " .. destino
  end
  disco.write(f, conteudo)
  disco.close(f)
  return true
end

local function exigir_disco()
  if not disco_escolhido then
    print("Nenhum disco selecionado. Usa 'discos' e depois 'usar <número>'.")
    return false
  end
  return true
end

local function executar_etapa(nome, modo_atualizar)
  if not exigir_disco() then return end
  local etapa = ETAPAS[nome]
  local disco = disco_escolhido.disco
  print((modo_atualizar and "Atualizando " or "Instalando ")
    .. etapa.descricao .. " em " .. disco_escolhido.endereco:sub(1, 8) .. "...")
  local _, y = term.getCursor()
  local erros = {}

  for i, f in ipairs(etapa.ficheiros) do
    desenhar_barra(i - 1, #etapa.ficheiros, etapa.descricao, y)

    local ok, conteudo = buscar_conteudo(f.url)
    if not ok then
      table.insert(erros, f.dest .. ": " .. tostring(conteudo))
    else
      -- Atualizar: guarda cópia da versão anterior antes de substituir
      local tinha_antigo = modo_atualizar and disco.exists(f.dest)
      if tinha_antigo then
        local antigo = disco.open(f.dest, "r")
        local partes = {}
        local bloco = disco.read(antigo, math.huge)
        while bloco do
          table.insert(partes, bloco)
          bloco = disco.read(antigo, math.huge)
        end
        disco.close(antigo)
        gravar(disco, f.dest .. ".bak", table.concat(partes))
      end

      local gravou, erro = gravar(disco, f.dest, conteudo)
      if not gravou then
        table.insert(erros, f.dest .. ": " .. tostring(erro))
        if tinha_antigo then
          -- restaura a versão anterior se a escrita falhar
          local bak = disco.open(f.dest .. ".bak", "r")
          local partes = {}
          local bloco = disco.read(bak, math.huge)
          while bloco do
            table.insert(partes, bloco)
            bloco = disco.read(bak, math.huge)
          end
          disco.close(bak)
          gravar(disco, f.dest, table.concat(partes))
        end
      end
    end
  end

  -- A etapa 'app' também cria a pasta onde as aplicações vão ficar
  if nome == "app" and not disco.exists("/BigornaOS/apps") then
    disco.makeDirectory("/BigornaOS/apps")
  end

  desenhar_barra(#etapa.ficheiros, #etapa.ficheiros, "concluído", y)
  print("")
  if #erros == 0 then
    print(etapa.descricao .. (modo_atualizar and " atualizado." or " instalado."))
  else
    for _, e in ipairs(erros) do print("  erro - " .. e) end
  end
end

local function verificar()
  if not exigir_disco() then return end
  local disco = disco_escolhido.disco

  local total = 0
  for _, nome in ipairs(ORDEM) do
    total = total + #ETAPAS[nome].ficheiros
  end

  local _, y = term.getCursor()
  local feitos = 0
  local em_falta = {}

  for _, nome in ipairs(ORDEM) do
    for _, f in ipairs(ETAPAS[nome].ficheiros) do
      desenhar_barra(feitos, total, f.dest, y)
      if not disco.exists(f.dest) then
        table.insert(em_falta, f.dest)
      end
      feitos = feitos + 1
    end
  end
  desenhar_barra(total, total, "concluído", y)
  print("")
  print("")

  if #em_falta == 0 then
    print("Todos os " .. total .. " ficheiros estão presentes.")
  else
    print(#em_falta .. " ficheiro(s) em falta:")
    for _, c in ipairs(em_falta) do print("  - " .. c) end
  end
end

local function atualizar()
  if not exigir_disco() then return end
  print("Atualizando todas as etapas. Cópias anteriores ficam com extensão .bak.")
  for _, nome in ipairs(ORDEM) do
    executar_etapa(nome, true)
  end
end

local function apagar_disco()
  if not exigir_disco() then return end
  io.write("Esse disco tem ficheiros do BigornaOS. Apagar tudo? [Y/N]: ")
  if io.read():upper() ~= "Y" then
    print("Cancelado.")
    return
  end
  for _, item in ipairs(disco_escolhido.disco.list("/") or {}) do
    pcall(disco_escolhido.disco.remove, "/" .. item)
  end
  print("Disco limpo.")
end

local function ajuda()
  print("Comandos:")
  print("  help                 mostra esta lista")
  print("  discos               lista os discos disponíveis")
  print("  usar <número>        escolhe o disco de instalação")
  print("  instalar <etapa>     etapas: " .. table.concat(ORDEM, ", "))
  print("  instalar todos       instala todas as etapas, por ordem")
  print("  verificar            mostra o progresso e confirma os ficheiros")
  print("  atualizar            atualiza todas as etapas (guarda .bak)")
  print("  rm HDD               apaga o disco escolhido (pede confirmação)")
  print("  reboot               reinicia o computador")
  print("  sair                 fecha o instalador")
end

local function listar()
  local discos = listar_discos()
  if #discos == 0 then
    print("Nenhum disco gravável encontrado.")
    return discos
  end
  for i, d in ipairs(discos) do
    print(i .. " - " .. d.endereco:sub(1, 8))
  end
  return discos
end

local function main()
  term.clear()
  print("==============================")
  print("           BigornaOS")
  print("==============================")
  print("Instalação manual, passo a passo.")
  print("Escreve 'help' para ver os comandos.")
  print("")

  local discos = {}
  while true do
    io.write("> ")
    local linha = io.read()
    if not linha then break end
    local cmd, arg = linha:match("^(%S+)%s*(.-)$")
    cmd = cmd and cmd:lower() or ""

    if cmd == "help" then
      ajuda()
    elseif cmd == "discos" then
      discos = listar()
    elseif cmd == "usar" then
      local n = tonumber(arg)
      if not discos[n] then
        print("Usa 'discos' primeiro e escolhe um número válido.")
      else
        disco_escolhido = discos[n]
        print("Disco selecionado: " .. disco_escolhido.endereco:sub(1, 8))
      end
    elseif cmd == "instalar" then
      if arg == "todos" then
        for _, nome in ipairs(ORDEM) do executar_etapa(nome, false) end
      elseif ETAPAS[arg] then
        executar_etapa(arg, false)
      else
        print("Etapa desconhecida. Usa 'help'.")
      end
    elseif cmd == "verificar" then
      verificar()
    elseif cmd == "atualizar" then
      atualizar()
    elseif cmd == "rm" and arg == "HDD" then
      apagar_disco()
    elseif cmd == "reboot" then
      print("A reiniciar...")
      computer.shutdown(true)
    elseif cmd == "sair" then
      break
    elseif cmd ~= "" then
      print("Comando desconhecido. Escreve 'help'.")
    end
  end
end

main()

-- BigornaOS - tela de arranque (/boot/carregador.lua)
-- Corre sem OpenOS, por isso usa a placa gráfica diretamente.

local gpu = component.gpu
local largura, altura = gpu.getResolution()

gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, largura, altura, " ")

local titulo = "BigornaOS"
local subtitulo = "A iniciar..."

gpu.set(math.floor((largura - #titulo) / 2) + 1, math.floor(altura / 2) - 1, titulo)
gpu.set(math.floor((largura - #subtitulo) / 2) + 1, math.floor(altura / 2) + 1, subtitulo)

-- Pausa breve para o nome ficar visível
computer.pullSignal(2)

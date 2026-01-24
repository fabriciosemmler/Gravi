# Gravi

Um monitor de gravação minimalista para OBS Studio, eliminando a incerteza durante suas gameplays.

## O Problema
Quem grava vídeos ou gameplays conhece o medo: jogar por horas apenas para descobrir que o OBS não estava gravando (ou estava com tela preta). Ficar dando `Alt-Tab` toda hora para verificar se a gravação está ativa quebra a imersão e o fluxo de trabalho.

## A Solução
O Gravi atua como um LED vermelho digital:
- **Indicador Visual:** Exibe um aviso "🔴 REC" discreto no canto da tela, sempre visível sobre o jogo.
- **Detecção Híbrida:** Monitora a pasta de vídeos em tempo real. Se o arquivo foi criado ou está crescendo de tamanho, a luz acende.
- **Alta Responsividade:** Desligamento automático (aprox. 3s) ao parar.

## 🛠️ Instalação e Uso

### Para Usuários
Não requer instalação de nenhum software adicional (se compilado).
1. Vá até a aba **[Releases](../../releases)** aqui no GitHub.
2. Baixe o arquivo `Gravi.exe` mais recente.
3. Execute o arquivo. O ícone aparecerá na bandeja do sistema e monitorará sua pasta configurada.

### Para Desenvolvedores (Código Fonte)
Se você quer estudar o código ou configurar sua pasta de vídeos:
1. Instale o [AutoHotkey v2](https://www.autohotkey.com/).
2. Clone ou baixe este repositório.
3. Abra o arquivo `src/gravi.ahk` em um editor de texto.
4. **Importante:** Edite a variável `PastaVideos` com o caminho onde você salva suas gravações.
5. Execute o arquivo.

## Contribuição
Este é um projeto Open-Source criado para auxiliar criadores de conteúdo. Sinta-se à vontade para abrir Issues ou Pull Requests!
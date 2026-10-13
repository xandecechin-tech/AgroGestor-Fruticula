# AgroGestor Frutícola — v0.9 (demonstração)

Aplicativo de gestão para fruticultura: áreas, safras, produtos, compras por embalagens, estoque, aplicações, mão de obra por diária, colheitas, vendas e custos.

## Publicar no GitHub Pages

1. Crie um repositório chamado `agrogestor-fruticola` no GitHub.
2. Extraia este ZIP e envie **os arquivos e pastas que estão dentro dele** para a raiz do repositório (não envie o ZIP como único arquivo).
3. No repositório, abra **Settings → Pages → Build and deployment**.
4. Em **Source**, escolha **Deploy from a branch**; selecione `main` e `/(root)`; salve.
5. Acesse `https://SEU-USUARIO.github.io/agrogestor-fruticola/` quando a publicação terminar.

Também é possível usar o workflow incluído em `.github/workflows/pages.yml`. Nesse caso, configure **Settings → Pages → Source → GitHub Actions**, em vez de Deploy from a branch. Escolha **apenas um** dos dois métodos.

## Arquivos principais

- `index.html`: aplicação web v0.9.
- `manifest.webmanifest`, `icon.svg`, `sw.js`: instalação como PWA e cache para acesso offline após primeiro carregamento.
- `schema.sql`: esboço de banco de dados para futura integração; **não** é banco conectado.
- `package.json`, `capacitor.config.json`, `scripts/`: preparação para Android (Capacitor).
- `electron/main.cjs`: preparação para Windows (Electron).
- `.github/workflows/pages.yml`: publicação opcional por GitHub Actions.

## Segurança e dados

**ATENÇÃO: ESTE É UM PROTÓTIPO.** Cadastro/login são simulados em `localStorage`, sem autenticação segura. Não use senhas reais, dados sensíveis nem confie neste aplicativo como registro definitivo. Os lançamentos ficam **somente no navegador/dispositivo** e não sincronizam com outros aparelhos. Faça backup JSON antes de trocar de navegador ou limpar dados. O Supabase ainda precisa ser integrado, com autenticação real e regras de acesso (RLS).

A publicação no GitHub Pages não transforma automaticamente o site em APK nem instalador Windows. Esses formatos precisam de compilação e testes específicos.

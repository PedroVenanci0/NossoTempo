# 📓 Nosso Espaço — Calendário Compartilhado (Bullet Journal Style)

Bem-vindo ao **Nosso Espaço**! Este é um aplicativo de calendário compartilhado minimalista e elegante desenvolvido em **Flutter Web**, projetado especificamente para casais organizarem seus cronogramas de encontros, lazer, viagens e rotinas de estudos em conjunto.

O design do aplicativo é inspirado na estética analógica e charmosa de um **Bullet Journal** (caderno de planejamento físico), com tons creme/off-white suaves, linhas de borda finas, fontes monoespaçadas no estilo máquina de escrever e uma barra lateral contendo uma **Grade Milimetrada** (papel quadriculado) real com checklist de metas.

---

## ✨ Recursos Principais

* **Estética Premium Bullet Journal:** Design minimalista baseado em caderno analógico físico, feito para ser agradável e confortável aos olhos no dia a dia.
* **Perfis de Acesso Individual (Login Local):** Telas de login minimalistas com seleção de perfil ("Pedro" ou "Namorada") e senha para identificar de quem é cada compromisso.
* **Privacidade e Compartilhamento:**
  * **Compromissos Compartilhados (Casal):** Visíveis para ambos (ex: programas juntos, viagens, jantares), destacados com um charmoso mini-coração vermelho.
  * **Compromissos Privados:** Visíveis apenas por quem os criou (ótimo para rotina de faculdade ou tarefas individuais).
* **Categorias Temáticas Coloridas:** Separação visual limpa para **Estudos / Faculdade** (com ícone de livro), **Encontros / Lazer**, **Trabalho**, **Viagens / Férias**, **Datas Especiais** e **Outros**.
* **Notas do Mês Dinâmicas:** Bloco de anotações livres do lado esquerdo com salvamento automático ao clicar fora.
* **Grade Milimetrada de Tarefas/Metas:** Um checklist quadriculado interativo para listar as metas conjuntas daquele mês.
* **Navegação de Meses Rápida:** Barra horizontal minimalista no topo direito para alternar rapidamente entre os meses do ano.

---

## ☁️ Como Funciona a Sincronização Sem Banco de Dados?

Para rodar 100% grátis no **GitHub Pages** (que hospeda apenas páginas estáticas) e ainda assim sincronizar seus eventos de forma bidirecional (Pedro adiciona -> Namorada vê), o aplicativo usa o próprio **GitHub como banco de dados**!

1. O aplicativo lê e escreve um arquivo chamado `dados_calendario.csv` direto em um repositório do GitHub usando a API REST do GitHub.
2. Cada um gera um token de acesso pessoal (PAT) simples no GitHub e insere nas configurações do app uma única vez.
3. Este token fica gravado de forma 100% segura **apenas localmente no seu próprio navegador** (no `localStorage`), garantindo total privacidade.
4. Quando alguém adiciona, edita ou exclui um evento, o Flutter constrói o arquivo CSV atualizado na memória e faz um commit automático direto na API do GitHub, sincronizando os dados instantaneamente para ambos!
5. Se o token não estiver configurado ou ocorrer uma falha de rede, o app roda em **Modo Offline** salvando os dados no cache do navegador para vocês continuarem usando normalmente.

---

## 🛠️ Passo a Passo: Configurando a Sincronização no App

Para ativar o compartilhamento entre você e sua namorada, siga estes passos simples:

### Passo 1: Criar o Arquivo CSV no seu Repositório
No repositório do GitHub onde você vai hospedar o site (ou em outro de sua escolha):
1. Crie um arquivo na raiz chamado `dados_calendario.csv`.
2. Cole a seguinte linha de cabeçalho inicial dentro do arquivo e faça o commit:
   ```csv
   id,usuario,data,titulo,descricao,tipo,categoria,corHex,concluido
   ```

### Passo 2: Gerar o Token de Acesso do GitHub (PAT)
Tanto você quanto sua namorada devem gerar um token de acesso para que o app possa fazer commits no repositório:
1. Acesse seu GitHub e vá em **Settings** (Configurações) no seu perfil.
2. No menu esquerdo, clique em **Developer Settings** (Configurações do Desenvolvedor) no final da página.
3. Vá em **Personal Access Tokens** -> **Tokens (classic)**.
4. Clique em **Generate new token (classic)**.
5. Dê um nome (ex: `Calendario App`) e selecione a permissão **`repo`** (que dá permissão de escrita e leitura nos seus repositórios).
6. Clique em **Generate token** no final e **copie o token gerado** (atenção: você não poderá vê-lo novamente!).

### Passo 3: Colar as Chaves nas Configurações do App
1. Abra o aplicativo de calendário no navegador.
2. Faça o login inicial com o seu perfil (Pedro ou Namorada) usando a senha padrão `1234`.
3. Clique no ícone de **Engrenagem** (Configurações) no canto superior direito.
4. Preencha os dados:
   * **GitHub Personal Access Token:** Cole o token (`ghp_...`) gerado no Passo 2.
   * **Repositório:** Digite `dono/nome-do-repositorio` (ex: `pedro/calendario-compartilhado`).
   * **Branch:** Digite `main` (ou o ramo correspondente ao seu repositório).
   * **Nome do Arquivo CSV:** Digite `dados_calendario.csv`.
   * *(Opcional)* Altere a senha padrão do seu perfil nos campos abaixo para maior segurança!
5. Clique em **Salvar Configurações**.
6. Pronto! Agora o ícone de sincronização no topo ficará ativo e vocês estarão conectados em tempo real!

---

## 🚀 Como Publicar no GitHub Pages

Para colocar o calendário no ar e usar no GitHub Pages de forma muito fácil, siga estes comandos no seu terminal:

1. **Gere a build web do Flutter:**
   Substitua `nome-do-repositorio` pelo nome exato do seu repositório no GitHub (respeitando maiúsculas e minúsculas).
   ```bash
   flutter build web --base-href "/nome-do-repositorio/" --release
   ```

2. **Publicar no GitHub Pages:**
   * Você pode criar uma branch chamada `gh-pages` e enviar o conteúdo da pasta `build/web` para ela.
   * Alternativamente, você pode usar o pacote `peanut` que faz isso de forma automática com um único comando:
     ```bash
     flutter pub global activate peanut
     peanut --web-renderer canvaskit
     git push origin gh-pages:gh-pages
     ```
   * Depois, vá nas configurações do seu repositório no GitHub (`Settings` -> `Pages`), certifique-se de que a branch de publicação está definida como `gh-pages` e salve. Em alguns minutos, seu app estará no ar no link: `https://seu-usuario.github.io/nome-do-repositorio/`.

---

## 💻 Executando Localmente para Desenvolvimento

Se você quiser rodar e fazer modificações no código localmente na sua máquina:

1. Tenha o **Flutter SDK** instalado no seu sistema.
2. Obtenha as dependências rodando:
   ```bash
   flutter pub get
   ```
3. Inicie o servidor de desenvolvimento local (no Chrome ou navegador preferido):
   ```bash
   flutter run -d chrome
   ```

---
*Feito com muito carinho e dedicação para organizar uma linda rotina de casal e estudos! 📓💖🎓*

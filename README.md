# 📝 To-Do List Application

Uma aplicação moderna de gerenciamento de tarefas com armazenamento local (localStorage) totalmente funcional.

## ✨ Recursos

### 🎯 Gerenciamento de Tarefas
- ✅ Adicionar novas tarefas com Enter ou clique no botão
- ✅ Marcar tarefas como concluídas
- ✅ Deletar tarefas individuais
- ✅ Limite de 100 tarefas por sessão
- ✅ Validação de entrada (máx 100 caracteres)

### 🔍 Filtros Inteligentes
- **Todas**: Exibe todas as tarefas
- **Ativas**: Mostra apenas tarefas não concluídas
- **Concluídas**: Mostra apenas tarefas completadas

### 📊 Estatísticas em Tempo Real
- Total de tarefas
- Tarefas ativas (não concluídas)
- Tarefas concluídas

### 💾 Armazenamento Persistente
- **localStorage**: Salva todas as tarefas automaticamente
- **Sem limite de espaço prático**: Suporta centenas de tarefas
- **Sincronização automática**: Dados persistem após fechar o navegador

### 📥📤 Import/Export
- **Exportar**: Salva todas as tarefas em arquivo `.json`
- **Importar**: Carrega tarefas de um arquivo `.json` anteriormente exportado
- **Merge automático**: Evita duplicação ao importar

### 🎨 Interface Moderna
- Design responsivo (mobile, tablet, desktop)
- Animações suaves e feedback visual
- Tema gradiente com cores modernas
- Notificações toast (toasts) informativas
- Ícones emojis intuitivos

### ⌨️ Atalhos de Teclado
- **Enter**: Adicionar nova tarefa
- **Ctrl/Cmd + S**: Exportar tarefas
- **Ctrl/Cmd + L**: Limpar tarefas concluídas

### 🛠️ Ações em Lote
- **Limpar Concluídas**: Remove todas as tarefas marcadas como feitas
- **Limpar Tudo**: Remove todas as tarefas (com confirmação)

## 📂 Estrutura de Arquivos

```
.
├── index.html       # Estrutura HTML
├── styles.css       # Estilos (Responsive CSS)
├── script.js        # Lógica JavaScript (vanilla)
└── README.md        # Documentação
```

## 🚀 Como Usar

### 1. Abrir a Aplicação
Simplemente abra o arquivo `index.html` em um navegador moderno.

```bash
open index.html
# ou
start index.html  # Windows
```

### 2. Adicionar Tarefas
1. Digite a tarefa no campo de entrada
2. Pressione `Enter` ou clique em **Adicionar**
3. A tarefa aparecerá no topo da lista

### 3. Gerenciar Tarefas
- **Marcar como Concluída**: Clique no checkbox
- **Deletar**: Clique no ícone 🗑️
- **Filtrar**: Use os botões Todas/Ativas/Concluídas

### 4. Exportar/Importar
- **Exportar**: Clique em 📥 Exportar para baixar um `.json`
- **Importar**: Clique em 📤 Importar e selecione um arquivo `.json`

## 🔧 Tecnologias

- **HTML5**: Semântica moderna
- **CSS3**: Flexbox, Grid, Gradientes, Animações
- **JavaScript Vanilla**: Sem dependências externas
- **localStorage API**: Armazenamento persistente
- **Blob API**: Export de arquivos
- **FileReader API**: Import de arquivos

## 📊 Estrutura de Dados

Cada tarefa é armazenada como um objeto JSON:

```json
{
  "id": 1719667200000,
  "text": "Exemplo de tarefa",
  "completed": false,
  "priority": "medium",
  "createdAt": "2024-06-29T13:20:00.000Z"
}
```

## 💡 Recursos Avançados

### Validações
✅ Entrada vazia (previne tarefas em branco)  
✅ Comprimento máximo de tarefa (100 caracteres)  
✅ Limite de tarefas (máx 100)  
✅ XSS Prevention (escape de HTML)  
✅ Validação ao importar arquivos  

### Segurança
- Escape de caracteres HTML para prevenir XSS
- Validação rigorosa de dados importados
- Confirmação antes de ações destrutivas
- Tratamento de erros robusto

### Performance
- Renderização otimizada
- Event delegation eficiente
- Sem bibliotecas externas (zero overhead)
- LocalStorage nativo (muito rápido)

## 🎮 Exemplos de Uso

### Adicionar tarefa
```javascript
// Digite: "Estudar JavaScript"
// Pressione: Enter
// Resultado: Tarefa adicionada no topo
```

### Exportar tarefas
```javascript
// Clique: 📥 Exportar
// Resultado: Download de "todo-list-2024-06-29.json"
```

### Importar tarefas
```javascript
// Clique: 📤 Importar
// Selecione: Arquivo JSON anterior
// Resultado: Tarefas mescladas sem duplicatas
```

## 🌐 Compatibilidade

| Navegador | Suporte |
|-----------|--------|
| Chrome    | ✅ 90+ |
| Firefox   | ✅ 88+ |
| Safari    | ✅ 14+ |
| Edge      | ✅ 90+ |
| Opera     | ✅ 76+ |

## 📝 Notas de Desenvolvedor

### localStorage vs. Alternativas
- ✅ localStorage é suficiente para esta aplicação
- ✅ Persiste 5-10MB por domínio (mais que o suficiente)
- ✅ Sem necessidade de servidor/banco de dados
- ✅ Privacidade garantida (dados locais apenas)

### Melhorias Futuras Possíveis
- [ ] Drag & drop para reordenar tarefas
- [ ] Categorias/Tags para tarefas
- [ ] Prioridades (Alta/Média/Baixa)
- [ ] Datas de vencimento e lembretes
- [ ] Sincronização em nuvem (Firebase/Supabase)
- [ ] PWA (Progressive Web App)
- [ ] Dark mode
- [ ] Busca e filtros avançados
- [ ] Subtarefas
- [ ] Repetição (tarefas recorrentes)

## 📄 Licença

Código livre para uso pessoal e educacional.

## 👨‍💻 Autor

Desenvolvido como exemplo de aplicação JavaScript vanilla com localStorage.

---

**Aproveite sua lista de tarefas! 🎉**
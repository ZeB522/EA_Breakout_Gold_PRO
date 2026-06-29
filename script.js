// ==================== CONSTANTS ====================
const STORAGE_KEY = 'todoList';
const MAX_TASKS = 100;

// ==================== DOM ELEMENTS ====================
const taskInput = document.getElementById('taskInput');
const addBtn = document.getElementById('addBtn');
const taskList = document.getElementById('taskList');
const emptyState = document.getElementById('emptyState');
const totalCount = document.getElementById('totalCount');
const activeCount = document.getElementById('activeCount');
const completedCount = document.getElementById('completedCount');
const filterBtns = document.querySelectorAll('.filter-btn');
const clearCompletedBtn = document.getElementById('clearCompletedBtn');
const clearAllBtn = document.getElementById('clearAllBtn');
const exportBtn = document.getElementById('exportBtn');
const importBtn = document.getElementById('importBtn');
const fileInput = document.getElementById('fileInput');
const toast = document.getElementById('toast');

// ==================== STATE ====================
let tasks = [];
let currentFilter = 'all';

// ==================== INITIALIZATION ====================
document.addEventListener('DOMContentLoaded', () => {
    loadFromStorage();
    renderTasks();
    setupEventListeners();
    console.log('✅ To-Do List Application Initialized');
});

// ==================== EVENT LISTENERS ====================
function setupEventListeners() {
    // Add Task
    addBtn.addEventListener('click', addTask);
    taskInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') addTask();
    });

    // Filter Tasks
    filterBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            filterBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            currentFilter = btn.dataset.filter;
            renderTasks();
        });
    });

    // Action Buttons
    clearCompletedBtn.addEventListener('click', clearCompleted);
    clearAllBtn.addEventListener('click', clearAll);
    exportBtn.addEventListener('click', exportTasks);
    importBtn.addEventListener('click', () => fileInput.click());
    fileInput.addEventListener('change', importTasks);
}

// ==================== TASK MANAGEMENT ====================

/**
 * Add a new task
 */
function addTask() {
    const text = taskInput.value.trim();

    if (!text) {
        showToast('⚠️ Digite uma tarefa!', 'error');
        return;
    }

    if (text.length > 100) {
        showToast('⚠️ Tarefa muito longa (máx 100 caracteres)', 'error');
        return;
    }

    if (tasks.length >= MAX_TASKS) {
        showToast(`❌ Máximo de ${MAX_TASKS} tarefas atingido`, 'error');
        return;
    }

    const newTask = {
        id: Date.now(),
        text: text,
        completed: false,
        priority: 'medium',
        createdAt: new Date().toISOString(),
    };

    tasks.unshift(newTask);
    saveToStorage();
    renderTasks();
    taskInput.value = '';
    taskInput.focus();
    showToast('✅ Tarefa adicionada!', 'success');
}

/**
 * Toggle task completion status
 */
function toggleTask(id) {
    const task = tasks.find(t => t.id === id);
    if (task) {
        task.completed = !task.completed;
        saveToStorage();
        renderTasks();
    }
}

/**
 * Delete a task
 */
function deleteTask(id) {
    tasks = tasks.filter(t => t.id !== id);
    saveToStorage();
    renderTasks();
    showToast('🗑️ Tarefa removida', 'info');
}

/**
 * Clear all completed tasks
 */
function clearCompleted() {
    const completedCount = tasks.filter(t => t.completed).length;
    if (completedCount === 0) {
        showToast('✅ Nenhuma tarefa concluída', 'info');
        return;
    }

    if (confirm(`Deseja remover ${completedCount} tarefa(s) concluída(s)?`)) {
        tasks = tasks.filter(t => !t.completed);
        saveToStorage();
        renderTasks();
        showToast(`🗑️ ${completedCount} tarefa(s) removida(s)`, 'success');
    }
}

/**
 * Clear all tasks
 */
function clearAll() {
    if (tasks.length === 0) {
        showToast('✅ Nenhuma tarefa para limpar', 'info');
        return;
    }

    if (confirm('⚠️ Deseja remover TODAS as tarefas? Esta ação não pode ser desfeita!')) {
        tasks = [];
        saveToStorage();
        renderTasks();
        showToast('🧹 Todas as tarefas foram removidas', 'success');
    }
}

// ==================== RENDERING ====================

/**
 * Render tasks based on filter
 */
function renderTasks() {
    const filteredTasks = getFilteredTasks();

    // Clear list
    taskList.innerHTML = '';

    // Show empty state if no tasks
    if (filteredTasks.length === 0) {
        emptyState.classList.remove('hidden');
        taskList.style.display = 'none';
    } else {
        emptyState.classList.add('hidden');
        taskList.style.display = 'block';
    }

    // Render each task
    filteredTasks.forEach(task => {
        const taskElement = createTaskElement(task);
        taskList.appendChild(taskElement);
    });

    // Update stats
    updateStats();
}

/**
 * Create a task element
 */
function createTaskElement(task) {
    const li = document.createElement('li');
    li.className = `task-item ${task.completed ? 'completed' : ''}`;
    li.id = `task-${task.id}`;

    const date = new Date(task.createdAt);
    const formattedDate = date.toLocaleDateString('pt-BR', { month: 'short', day: 'numeric' });

    li.innerHTML = `
        <input 
            type="checkbox" 
            class="task-checkbox" 
            ${task.completed ? 'checked' : ''}
            onchange="toggleTask(${task.id})"
        >
        <div class="task-text">${escapeHtml(task.text)}</div>
        <span class="task-date">${formattedDate}</span>
        <span class="task-priority priority-${task.priority}">${task.priority.toUpperCase()}</span>
        <div class="task-actions">
            <button class="task-btn delete-btn" onclick="deleteTask(${task.id})" title="Deletar">🗑️</button>
        </div>
    `;

    return li;
}

/**
 * Update statistics
 */
function updateStats() {
    const total = tasks.length;
    const active = tasks.filter(t => !t.completed).length;
    const completed = tasks.filter(t => t.completed).length;

    totalCount.textContent = total;
    activeCount.textContent = active;
    completedCount.textContent = completed;

    // Show/hide clear completed button
    clearCompletedBtn.style.display = completed > 0 ? 'flex' : 'none';
}

/**
 * Get filtered tasks based on current filter
 */
function getFilteredTasks() {
    switch (currentFilter) {
        case 'active':
            return tasks.filter(t => !t.completed);
        case 'completed':
            return tasks.filter(t => t.completed);
        default:
            return tasks;
    }
}

// ==================== STORAGE ====================

/**
 * Save tasks to localStorage
 */
function saveToStorage() {
    try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(tasks));
        console.log('💾 Tasks saved to localStorage');
    } catch (error) {
        console.error('❌ Error saving to localStorage:', error);
        showToast('❌ Erro ao salvar tarefas', 'error');
    }
}

/**
 * Load tasks from localStorage
 */
function loadFromStorage() {
    try {
        const storedTasks = localStorage.getItem(STORAGE_KEY);
        if (storedTasks) {
            tasks = JSON.parse(storedTasks);
            console.log(`📥 Loaded ${tasks.length} tasks from localStorage`);
        }
    } catch (error) {
        console.error('❌ Error loading from localStorage:', error);
        tasks = [];
        showToast('❌ Erro ao carregar tarefas', 'error');
    }
}

// ==================== IMPORT/EXPORT ====================

/**
 * Export tasks to JSON file
 */
function exportTasks() {
    if (tasks.length === 0) {
        showToast('⚠️ Nenhuma tarefa para exportar', 'error');
        return;
    }

    const dataStr = JSON.stringify(tasks, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `todo-list-${new Date().toISOString().split('T')[0]}.json`;
    link.click();
    URL.revokeObjectURL(url);
    showToast('📥 Tarefas exportadas!', 'success');
}

/**
 * Import tasks from JSON file
 */
function importTasks(event) {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
        try {
            const importedData = JSON.parse(e.target.result);

            if (!Array.isArray(importedData)) {
                throw new Error('Formato inválido. Esperado um array de tarefas.');
            }

            // Validate and merge tasks
            const validTasks = importedData.filter(t =>
                t.id && t.text && typeof t.completed === 'boolean'
            );

            if (validTasks.length === 0) {
                throw new Error('Nenhuma tarefa válida encontrada no arquivo.');
            }

            // Merge with existing tasks (avoid duplicates)
            const existingIds = new Set(tasks.map(t => t.id));
            const newTasks = validTasks.filter(t => !existingIds.has(t.id));

            tasks.push(...newTasks);
            tasks.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
            saveToStorage();
            renderTasks();
            showToast(`📤 ${newTasks.length} tarefa(s) importada(s)!`, 'success');
        } catch (error) {
            console.error('❌ Error importing tasks:', error);
            showToast(`❌ Erro ao importar: ${error.message}`, 'error');
        }
    };
    reader.readAsText(file);
    fileInput.value = ''; // Reset file input
}

// ==================== UTILITIES ====================

/**
 * Escape HTML to prevent XSS
 */
function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;',
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}

/**
 * Show toast notification
 */
function showToast(message, type = 'info') {
    toast.textContent = message;
    toast.className = `toast show ${type}`;

    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

// ==================== KEYBOARD SHORTCUTS ====================
document.addEventListener('keydown', (e) => {
    // Ctrl/Cmd + S: Export
    if ((e.ctrlKey || e.metaKey) && e.key === 's') {
        e.preventDefault();
        exportTasks();
    }

    // Ctrl/Cmd + L: Clear completed
    if ((e.ctrlKey || e.metaKey) && e.key === 'l') {
        e.preventDefault();
        clearCompleted();
    }
});

console.log('🎯 To-Do List Application Ready!\n📌 Shortcuts:\n• Enter: Add task\n• Ctrl+S: Export\n• Ctrl+L: Clear completed');
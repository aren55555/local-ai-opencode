import { createSignal, onMount } from 'solid-js'
import './App.css'

function App() {
  const [todos, setTodos] = createSignal([])
  const [inputValue, setInputValue] = createSignal('')

  // Load todos from localStorage on mount
  onMount(() => {
    const savedTodos = localStorage.getItem('todos')
    if (savedTodos) {
      setTodos(JSON.parse(savedTodos))
    }
  })

  // Save todos to localStorage whenever they change
  const saveTodos = (newTodos) => {
    setTodos(newTodos)
    localStorage.setItem('todos', JSON.stringify(newTodos))
  }

  const addTodo = () => {
    const value = inputValue().trim()
    if (value) {
      const newTodos = [...todos(), { id: Date.now(), text: value, completed: false }]
      saveTodos(newTodos)
      setInputValue('')
    }
  }

  const toggleTodo = (id) => {
    const newTodos = todos().map(todo =>
      todo.id === id ? { ...todo, completed: !todo.completed } : todo
    )
    saveTodos(newTodos)
  }

  const deleteTodo = (id) => {
    const newTodos = todos().filter(todo => todo.id !== id)
    saveTodos(newTodos)
  }

  const handleKeyPress = (e) => {
    if (e.key === 'Enter') {
      addTodo()
    }
  }

  return (
    <div class="app">
      <h1>TODO List</h1>
      <div class="input-container">
        <input
          type="text"
          value={inputValue()}
          onInput={(e) => setInputValue(e.target.value)}
          onKeyPress={handleKeyPress}
          placeholder="Add a new todo..."
        />
        <button onClick={addTodo}>Add</button>
      </div>
      <ul class="todo-list">
        {todos().map(todo => (
          <li class={`todo-item ${todo.completed ? 'completed' : ''}`}>
            <span onClick={() => toggleTodo(todo.id)}>{todo.text}</span>
            <button onClick={() => deleteTodo(todo.id)}>Delete</button>
          </li>
        ))}
      </ul>
      {todos().length === 0 && <p class="empty-message">No todos yet. Add one above!</p>}
    </div>
  )
}

export default App

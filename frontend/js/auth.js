// Функция для проверки аутентификации
async function login(username, password) {
    console.log("Попытка входа:", username, password);
    
    // В реальном приложении здесь должен быть запрос к серверу
    // Для демонстрации используем жестко заданные credentials
    if (username === 'roma' && password === 'chort') {
        console.log("Успешная авторизация!");
        localStorage.setItem('authenticated', 'true');
        localStorage.setItem('username', username);
        return true;
    }
    
    console.log("Неверные учетные данные");
    return false;
}

function logout() {
    localStorage.removeItem('authenticated');
    localStorage.removeItem('username');
    window.location.href = 'login.html';
}

function isAuthenticated() {
    return localStorage.getItem('authenticated') === 'true';
}

function getCurrentUser() {
    return localStorage.getItem('username');
}

// Проверка аутентификации при загрузке страницы
document.addEventListener('DOMContentLoaded', function() {
    if (window.location.pathname !== '/login.html' && !isAuthenticated()) {
        window.location.href = 'login.html';
    }
});

// Экспортируем функции для использования в других модулях
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        login,
        logout,
        isAuthenticated,
        getCurrentUser
    };
}
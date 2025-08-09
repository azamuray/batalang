import json
from typing import Dict

from flask import Flask, render_template, request
from flask_socketio import SocketIO, emit, join_room, leave_room
import random
import time

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'
socketio = SocketIO(app)


def get_words() -> Dict:
    with open("words.json", "r") as file:
        words = json.load(file)

        return words


# База данных слов: английское слово -> перевод
WORDS = get_words()

# Очередь ожидающих игроков
waiting_players = []
# Активные игры: room_id -> {'players': [player1, player2], 'word': word, 'translations': []}
active_games = {}


@app.route('/')
def index():
    return render_template('index.html')


@socketio.on('connect')
def handle_connect():
    print(f'Client connected: {request.sid}')


@socketio.on('disconnect')
def handle_disconnect():
    print(f'Client disconnected: {request.sid}')
    # Удаляем игрока из очереди или активной игры
    if request.sid in waiting_players:
        waiting_players.remove(request.sid)
    else:
        for room_id, game in active_games.items():
            if request.sid in game['players']:
                leave_room(room_id)
                opponent = game['players'][0] if game['players'][1] == request.sid else game['players'][1]
                emit('opponent_disconnected', room=opponent)
                del active_games[room_id]
                break


@socketio.on('find_game')
def handle_find_game():
    if request.sid in waiting_players:
        return

    waiting_players.append(request.sid)
    print(f'Player {request.sid} is waiting for a game')

    # Если есть хотя бы 2 игрока, создаем игру
    if len(waiting_players) >= 2:
        player1 = waiting_players.pop(0)
        player2 = waiting_players.pop(0)

        room_id = f"room_{player1}_{player2}"
        join_room(room_id, player1)
        join_room(room_id, player2)

        # Выбираем случайное слово
        word, translation = random.choice(list(WORDS.items()))
        # Создаем варианты ответов
        translations = list(random.sample(list(WORDS.values()), 10))
        random.shuffle(translations)
        if translation not in translations[:3]:
            translations[3] = translation
        random.shuffle(translations)

        game_data = {
            'players': [player1, player2],
            'word': word,
            'translations': translations,
            'scores': {player1: 0, player2: 0}
        }
        active_games[room_id] = game_data

        # Отправляем данные игрокам
        emit('game_start', {
            'word': word,
            'translations': translations,
            'opponent_connected': True
        }, room=player1)

        emit('game_start', {
            'word': word,
            'translations': translations,
            'opponent_connected': True
        }, room=player2)


@socketio.on('answer')
def handle_answer(data):
    room_id = None
    # Находим комнату, где находится игрок
    for r_id, game in active_games.items():
        if request.sid in game['players']:
            room_id = r_id
            break

    if not room_id:
        return

    game = active_games[room_id]
    word = game['word']
    correct_translation = WORDS[word]

    if data['answer'] == correct_translation:
        # Игрок ответил правильно
        game['scores'][request.sid] += 1
        print(f"Игрок {request.sid} ответил правильно. Текущий счет: {game['scores']}")
        
        # Проверяем, достиг ли кто-то 15 очков
        if game['scores'][request.sid] >= 15:
            print(f"Игра завершена! Победитель: {request.sid} с {game['scores'][request.sid]} очками")
            # Игра завершена - победитель найден
            winner = request.sid
            loser = game['players'][0] if game['players'][1] == request.sid else game['players'][1]
            
            # Отправляем сообщение о завершении игры победителю
            emit('game_over', {
                'winner': True,
                'message': 'Поздравляем! Вы победили!',
                'final_scores': game['scores']
            }, room=winner)
            
            # Отправляем сообщение о завершении игры проигравшему
            emit('game_over', {
                'winner': False,
                'message': 'Игра окончена. Вы проиграли.',
                'final_scores': game['scores']
            }, room=loser)
            
            # Удаляем игру из активных
            del active_games[room_id]
            print(f"Игра {room_id} удалена из активных игр")
            return

        # Отправляем результат
        emit('answer_result', {
            'correct': True,
            'your_score': game['scores'][request.sid],
            'opponent_score': game['scores'][game['players'][0]] if game['players'][1] == request.sid else
            game['scores'][game['players'][1]],
            'correct_answer': correct_translation
        }, room=request.sid)

        # Отправляем оппоненту, что он проиграл этот раунд
        opponent = game['players'][0] if game['players'][1] == request.sid else game['players'][1]
        emit('answer_result', {
            'correct': False,
            'your_score': game['scores'][opponent],
            'opponent_score': game['scores'][request.sid],
            'correct_answer': correct_translation
        }, room=opponent)

        # Выбираем новое слово
        time.sleep(2)  # Пауза перед новым раундом
        word, translation = random.choice(list(WORDS.items()))
        translations = list(random.sample(list(WORDS.values()), 10))
        random.shuffle(translations)
        if translation not in translations[:3]:
            translations[3] = translation
        random.shuffle(translations)

        game['word'] = word
        game['translations'] = translations

        # Отправляем новое слово обоим игрокам
        emit('new_round', {
            'word': word,
            'translations': translations
        }, room=room_id)
    else:
        # Игрок ответил неправильно
        emit('answer_result', {
            'correct': False,
            'your_score': game['scores'][request.sid],
            'opponent_score': game['scores'][game['players'][0]] if game['players'][1] == request.sid else
            game['scores'][game['players'][1]],
            'correct_answer': correct_translation
        }, room=request.sid)


if __name__ == '__main__':
    socketio.run(app, debug=True)

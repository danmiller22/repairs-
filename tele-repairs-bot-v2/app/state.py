# простое in-memory хранилище
_store = {}

class StateStore:
    def get(self, chat_id):
        return _store.get(int(chat_id))

    def set(self, chat_id, state, form):
        _store[int(chat_id)] = {"state": state, "form": dict(form or {})}

    def clear(self, chat_id):
        _store.pop(int(chat_id), None)

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/chat_api.dart';
import '../../core/api/providers.dart';
import '../../core/auth/auth_session.dart';
import 'triage_card.dart';

/// Gjendjet e udhëzimit: bosh, duke shkruar, duke transmetuar, gabim, emergjencë.
enum ChatStatus { idle, streaming, error }

/// Një mesazh i vetëm në listë.
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.triage,
    this.emergency,
    this.blocked = false,
    this.sources = const [],
  });

  final String role; // user | assistant
  final String text;
  final TriageData? triage;
  final String? emergency; // mesazhi i plotë i emergjencës (numri 194)
  final bool blocked;
  final List<Map<String, String>> sources;

  ChatMessage copyWith({
    String? text,
    TriageData? triage,
    String? emergency,
    bool? blocked,
    List<Map<String, String>>? sources,
  }) => ChatMessage(
    role: role,
    text: text ?? this.text,
    triage: triage ?? this.triage,
    emergency: emergency ?? this.emergency,
    blocked: blocked ?? this.blocked,
    sources: sources ?? this.sources,
  );
}

/// Një veprim që pret konfirmimin e përdoruesit (kujtesë ilaçi).
class PendingAction {
  const PendingAction({
    required this.id,
    required this.medication,
    required this.times,
  });
  final String id;
  final String medication;
  final List<String> times;
}

class ChatState {
  const ChatState({
    this.status = ChatStatus.idle,
    this.messages = const [],
    this.conversationId,
    this.actions = const [],
    this.errorMessage,
    this.reachedLimit = false,
    this.offline = false,
    this.unauthorized = false,
  });

  final ChatStatus status;
  final List<ChatMessage> messages;
  final String? conversationId;
  final List<PendingAction> actions;
  final String? errorMessage;
  final bool reachedLimit;
  final bool offline;
  final bool unauthorized;

  bool get isStreaming => status == ChatStatus.streaming;

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    String? conversationId,
    List<PendingAction>? actions,
    String? errorMessage,
    bool clearError = false,
    bool reachedLimit = false,
    bool offline = false,
    bool? unauthorized,
  }) => ChatState(
    status: status ?? this.status,
    messages: messages ?? this.messages,
    conversationId: conversationId ?? this.conversationId,
    actions: actions ?? this.actions,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    reachedLimit: reachedLimit,
    offline: offline,
    unauthorized: unauthorized ?? this.unauthorized,
  );
}

/// Kontrolluesi i gjendjes. Mban buffer-in e tokenëve dhe e shkruan në ekran
/// çdo 40 ms (udhëzimi: "grupo përditësimet çdo 30 deri 50 ms").
class ChatController extends Notifier<ChatState> {
  StreamSubscription<ChatEvent>? _sub;
  late final ChatApi _api;
  final _buffer = StringBuffer();
  DateTime _lastFlush = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  ChatState build() {
    // Merret këtu (jo brenda onDispose): Riverpod 3 nuk lejon lexim providerash
    // brenda cikleve të jetës.
    _api = ref.read(chatApiProvider);
    ref.onDispose(() {
      _sub?.cancel();
      _api.dispose();
    });
    return const ChatState();
  }

  /// Dërgon mesazhin dhe transmeton përgjigjen ngjarje pas ngjarjeje.
  void send(String raw) {
    final text = raw.trim();
    if (text.isEmpty || state.isStreaming) return;

    _buffer.clear();
    state = state.copyWith(
      status: ChatStatus.streaming,
      messages: [
        ...state.messages,
        ChatMessage(role: 'user', text: text),
      ],
      clearError: true,
      reachedLimit: false,
      unauthorized: false,
    );

    _sub?.cancel();
    _sub = _api
        .stream(text, conversationId: state.conversationId)
        .listen(
          _onEvent,
          onError: _onError,
          onDone: _onDone,
          cancelOnError: true,
        );
  }

  /// Konfirmon veprimin te backend-i. Klienti nuk dërgon asnjë të dhënë veç ID-së.
  Future<void> confirmAction(PendingAction action) async {
    try {
      await _api.confirmAction(action.id);
      state = state.copyWith(
        actions: [
          for (final a in state.actions)
            if (a.id != action.id) a,
        ],
      );
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Nuk u konfirmua veprimi. Provo përsëri.',
      );
    }
  }

  void dismissAction(String id) {
    state = state.copyWith(
      actions: [
        for (final a in state.actions)
          if (a.id != id) a,
      ],
    );
  }

  void setOffline(bool value) => state = state.copyWith(offline: value);

  void _onEvent(ChatEvent event) {
    switch (event.name) {
      case 'meta':
        state = state.copyWith(
          conversationId: '${event.data['conversation_id']}',
        );
        break;

      case 'token':
        _buffer.write(event.data['t'] ?? '');
        _flush(force: false);
        break;

      case 'triage':
        _flush(force: true);
        _appendAssistant('', triage: TriageData.fromApi(event.data));
        break;

      case 'emergency':
        _flush(force: true);
        _appendAssistant('', emergency: '${event.data['message']}');
        break;

      case 'confirm':
        state = state.copyWith(
          actions: [
            ...state.actions,
            PendingAction(
              id: '${event.data['action_id']}',
              medication: '${event.data['medication']}',
              times: List<String>.from(event.data['times'] as List),
            ),
          ],
        );
        break;

      case 'blocked':
        _flush(force: true);
        _appendAssistant('${event.data['message']}', blocked: true);
        break;

      case 'error':
        state = state.copyWith(errorMessage: '${event.data['message']}');
        break;

      case 'done':
        _flush(force: true);
        break;
    }
  }

  void _flush({required bool force}) {
    if (_buffer.isEmpty) return;
    final now = DateTime.now();
    if (!force && now.difference(_lastFlush).inMilliseconds < 40) return;
    _lastFlush = now;

    final chunk = _buffer.toString();
    _buffer.clear();

    final last = state.messages.isNotEmpty ? state.messages.last : null;
    final appendable =
        last != null &&
        last.role == 'assistant' &&
        last.triage == null &&
        last.emergency == null &&
        !last.blocked;

    if (appendable) {
      state = state.copyWith(
        messages: [
          ...state.messages.sublist(0, state.messages.length - 1),
          last.copyWith(text: last.text + chunk),
        ],
      );
    } else {
      _appendAssistant(chunk);
    }
  }

  void _appendAssistant(
    String text, {
    TriageData? triage,
    String? emergency,
    bool blocked = false,
  }) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          role: 'assistant',
          text: text,
          triage: triage,
          emergency: emergency,
          blocked: blocked,
        ),
      ],
    );
  }

  void _onError(Object error) {
    if (error is ChatApiException) {
      if (error.statusCode == 401) {
        // Sesioni ka skaduar: pastro tokenin dhe kthe përdoruesin te hyrja.
        unawaited(ref.read(secureStoreProvider).clear());
        ref.read(authSessionProvider).setAuthenticated(false);
      }
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: error.userMessage,
        reachedLimit: error.statusCode == 429,
        unauthorized: error.statusCode == 401,
      );
    } else {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: 'Nuk u lidhëm. Provo përsëri pas pak. Nëse është urgjente, telefono 194.',
        unauthorized: false,
      );
    }
  }

  void _onDone() {
    _flush(force: true);
    state = state.copyWith(status: ChatStatus.idle);
  }
}

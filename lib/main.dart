// Onitama - Flutter implementation (pass-and-play)
// Updated version based on Leonardo Castro's requests

import 'package:flutter/material.dart';

void main() => runApp(OnitamaApp());

class OnitamaApp extends StatelessWidget {
  const OnitamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onitama - Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: OnitamaHome(),
    );
  }
}

enum PieceType { Master, Student }

enum PlayerColor { Red, Blue }

class Piece {
  final PlayerColor owner;
  final PieceType type;
  Piece(this.owner, this.type);
}

class CardModel {
  final String name;
  final List<Point> moves;
  final Color color;
  CardModel(this.name, this.moves, this.color);
}

class Point {
  final int r;
  final int c;
  const Point(this.r, this.c);
}

class OnitamaHome extends StatefulWidget {
  const OnitamaHome({super.key});

  @override
  _OnitamaHomeState createState() => _OnitamaHomeState();
}

class _OnitamaHomeState extends State<OnitamaHome> {
  static const int size = 5;

  List<List<Piece?>> board = List.generate(size, (_) => List.generate(size, (_) => null));

  late List<CardModel> allCards;
  List<CardModel> redHand = [];
  List<CardModel> blueHand = [];
  late CardModel reserveCard;

  PlayerColor currentPlayer = PlayerColor.Red;

  CardModel? selectedCardForMove;
  Point? selectedCell;
  String message = '';

  @override
  void initState() {
    super.initState();
    _setupCards();
    _setupBoard();
  }

  void _setupBoard() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) board[r][c] = null;
    }

    board[0][0] = Piece(PlayerColor.Red, PieceType.Student);
    board[0][1] = Piece(PlayerColor.Red, PieceType.Student);
    board[0][2] = Piece(PlayerColor.Red, PieceType.Master);
    board[0][3] = Piece(PlayerColor.Red, PieceType.Student);
    board[0][4] = Piece(PlayerColor.Red, PieceType.Student);

    board[4][0] = Piece(PlayerColor.Blue, PieceType.Student);
    board[4][1] = Piece(PlayerColor.Blue, PieceType.Student);
    board[4][2] = Piece(PlayerColor.Blue, PieceType.Master);
    board[4][3] = Piece(PlayerColor.Blue, PieceType.Student);
    board[4][4] = Piece(PlayerColor.Blue, PieceType.Student);

    selectedCardForMove = null;
    selectedCell = null;
    currentPlayer = PlayerColor.Red;
    message = 'Red começa!';
  }

  void _setupCards() {
    allCards = [
      CardModel('Tiger', [Point(-1, 0), Point(2, 0)], Colors.orange),
      CardModel('Dragon', [Point(1, 2), Point(1, -2), Point(-1, 1), Point(-1, -1)], Colors.teal),
      CardModel('Frog', [Point(0, 2), Point(1, 1), Point(-1, -1)], Colors.cyan),
      CardModel('Rabbit', [Point(-1, 1), Point(1, -1), Point(0, -2)], Colors.pinkAccent),
      CardModel('Crab', [Point(0, -2), Point(0, 2), Point(1, 0)], Colors.blueGrey),
      CardModel('Elephant', [Point(0, -1), Point(0, 1), Point(1, -1), Point(1, 1)], Colors.purple),
      CardModel('Goose', [Point(0, -1), Point(0, 1), Point(-1, -1), Point(1, 1)], Colors.yellow),
      CardModel('Rooster', [Point(0, -1), Point(0, 1), Point(-1, 1), Point(1, -1)], Colors.deepOrangeAccent),
      CardModel('Monkey', [Point(-1, -1), Point(-1, 1), Point(1, -1), Point(1, 1)], Colors.brown),
      CardModel('Mantis', [Point(-1, -1), Point(-1, 1), Point(1, 0)], Colors.green),
      CardModel('Horse', [Point(-1, 0), Point(1, 0), Point(0, 1)], Colors.deepPurpleAccent),
      CardModel('Ox', [Point(-1, 0), Point(1, 0), Point(0, -1)], Colors.lightBlueAccent),
      CardModel('Crane', [Point(1, 0), Point(-1, 1), Point(-1, -1)], Colors.lightGreen),
      CardModel('Boar', [Point(0, -1), Point(0, 1), Point(1, 0)], Colors.redAccent),
      CardModel('Eel', [Point(1, 1), Point(-1, 1), Point(0, -1)], Colors.indigo),
      CardModel('Cobra', [Point(-1, -1), Point(1, -1), Point(0, 1)], Colors.amber),
    ];

    allCards.shuffle();
    redHand = [allCards[0], allCards[1]];
    blueHand = [allCards[2], allCards[3]];
    reserveCard = allCards[4];
  }

  bool _isInside(int r, int c) => r >= 0 && r < size && c >= 0 && c < size;

  List<Point> _availableMovesForCell(int r, int c, CardModel card, PlayerColor who) {
    final piece = board[r][c];
    if (piece == null || piece.owner != who) return [];

    bool isRed = who == PlayerColor.Red;
    List<Point> targets = [];
    for (var mv in card.moves) {
      int dr = isRed ? mv.r : -mv.r;
      int dc = isRed ? mv.c : -mv.c;
      int nr = r + dr;
      int nc = c + dc;
      if (_isInside(nr, nc) && board[nr][nc]?.owner != who) targets.add(Point(nr, nc));
    }
    return targets;
  }

  void _onCellTap(int r, int c) {
    setState(() {
      final piece = board[r][c];
      if ((selectedCell == null || piece != null) && (piece != null && piece.owner == currentPlayer)) {
        selectedCell = Point(r, c);
        message = 'Peça selecionada em ($r,$c)';
      } else if (selectedCardForMove != null) {
        final from = selectedCell!;
        final moves = _availableMovesForCell(from.r, from.c, selectedCardForMove!, currentPlayer);
        bool allowed = moves.any((p) => p.r == r && p.c == c);

        if (!allowed) {
          message = 'Movimento inválido';
          return;
        }

        final moving = board[from.r][from.c];
        board[r][c] = moving;
        board[from.r][from.c] = null;

        _swapCardWithReserve(selectedCardForMove!);
        selectedCardForMove = null;
        selectedCell = null;

        if (_isWinByCapture()) {
          _showEndDialog('${_playerName(currentPlayer)} venceu por captura!');
          return;
        }

        if (_isWinByTemple(r, c, currentPlayer)) {
          _showEndDialog('${_playerName(currentPlayer)} venceu por templo!');
          return;
        }

        currentPlayer = _opponent(currentPlayer);
        message = '${_playerName(currentPlayer)} joga agora';
      }
    });
  }

  void _swapCardWithReserve(CardModel used) {
    List<CardModel> hand = currentPlayer == PlayerColor.Red ? redHand : blueHand;
    int idx = hand.indexWhere((c) => c.name == used.name);
    if (idx == -1) return;
    hand[idx] = reserveCard;
    reserveCard = used;
  }

  bool _isWinByCapture() {
    bool redMasterAlive = false;
    bool blueMasterAlive = false;
    for (var row in board) {
      for (var piece in row) {
        if (piece?.type == PieceType.Master) {
          if (piece!.owner == PlayerColor.Red) redMasterAlive = true;
          if (piece.owner == PlayerColor.Blue) blueMasterAlive = true;
        }
      }
    }
    return !redMasterAlive || !blueMasterAlive;
  }

  bool _isWinByTemple(int r, int c, PlayerColor who) {
    if (who == PlayerColor.Red) return r == 4 && c == 2 && board[r][c]?.type == PieceType.Master;
    return r == 0 && c == 2 && board[r][c]?.type == PieceType.Master;
  }

  PlayerColor _opponent(PlayerColor p) => p == PlayerColor.Red ? PlayerColor.Blue : PlayerColor.Red;
  String _playerName(PlayerColor p) => p == PlayerColor.Red ? 'Vermelho' : 'Azul';

  void _onCardTap(CardModel card) {
    setState(() {
      final hand = currentPlayer == PlayerColor.Red ? redHand : blueHand;
      if (!hand.any((c) => c.name == card.name)) {
        message = 'Carta não pertence a você';
        return;
      }
      selectedCardForMove = card;
      message = 'Carta ${card.name} selecionada';
    });
  }

  void _showEndDialog(String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Fim de jogo'),
        content: Text(text),
        actions: [
          TextButton(
            child: Text('Reiniciar'),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _setupCards();
                _setupBoard();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(width: 2)),
        child: GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: size),
          itemCount: size * size,
          itemBuilder: (context, index) {
            int r = index ~/ size;
            int c = index % size;
            final piece = board[r][c];
            final isSelected = selectedCell != null && selectedCell!.r == r && selectedCell!.c == c;

            List<Point> highlights = [];
            if (selectedCell != null && selectedCardForMove != null) {
              highlights = _availableMovesForCell(selectedCell!.r, selectedCell!.c, selectedCardForMove!, currentPlayer);
            }
            bool isHighlighted = highlights.any((p) => p.r == r && p.c == c);

            return GestureDetector(
              onTap: () => _onCellTap(r, c),
              child: Container(
                margin: EdgeInsets.all(1),
                color: (r + c) % 2 == 0 ? Colors.grey.shade200 : Colors.grey.shade300,
                child: Stack(
                  children: [
                    if (isHighlighted) Positioned.fill(child: Container(color: Colors.yellow.withOpacity(0.35))),
                    if (isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(width: 3, color: Colors.greenAccent)),
                        ),
                      ),
                    Center(child: piece == null ? SizedBox() : _buildPieceWidget(piece)),
                    if ((r == 0 && c == 2) || (r == 4 && c == 2)) Positioned(top: 4, left: 4, child: Icon(Icons.location_on, size: 14, color: Colors.black26)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPieceWidget(Piece p) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: p.owner == PlayerColor.Red ? Colors.red : Colors.blue,
      child: Text(
        p.type == PieceType.Master ? 'M' : 'S',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCardWidget(CardModel c, {bool selectable = true}) {
    bool isSelectedCard = selectedCardForMove?.name == c.name;

    bool shouldntInvert = redHand.contains(c);
    final moves = shouldntInvert ? c.moves : _invertMoves(c.moves);

    return GestureDetector(
      onTap: selectable ? () => _onCardTap(c) : null,
      child: Container(
        width: 110,
        margin: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.color.withOpacity(0.12),
          border: Border.all(color: isSelectedCard ? Colors.green : Colors.black12, width: isSelectedCard ? 3 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.name, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            _buildMovesMiniGrid(moves),
          ],
        ),
      ),
    );
  }

  Widget _buildMovesMiniGrid(List<Point> moves) {
    List<Widget> cells = [];
    for (int rr = -2; rr <= 2; rr++) {
      for (int cc = -2; cc <= 2; cc++) {
        bool hasMove = moves.any((m) => m.r == rr && m.c == cc);
        bool isCenter = rr == 0 && cc == 0;
        cells.add(
          Container(
            width: 14,
            height: 14,
            margin: EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              color: hasMove
                  ? Colors.black26
                  : isCenter
                  ? Colors.red
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        );
      }
    }
    return Wrap(spacing: 0, runSpacing: 0, children: cells);
  }

  List<Point> _invertMoves(List<Point> moves) {
    return moves.map((m) => Point((m.r * -1), (m.c * -1))).toList();
  }

  Widget _buildHands(PlayerColor player) {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: (player == PlayerColor.Red ? redHand : blueHand).map((c) => _buildCardWidget(c)).toList()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(message),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _setupCards();
                _setupBoard();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(color: Colors.grey.shade100, padding: EdgeInsets.symmetric(vertical: 8), child: _buildHands(PlayerColor.Red)),
          Expanded(child: Center(child: _buildBoard())),
          Container(color: Colors.grey.shade100, padding: EdgeInsets.symmetric(vertical: 8), child: _buildHands(PlayerColor.Blue)),
          Text('Reserva'),
          _buildCardWidget(reserveCard, selectable: false),
        ],
      ),
    );
  }
}

import { promptAction } from '@kit.ArkUI';

const SHUFFLE_MOVES = 200;

interface Position {
  row: number;
  col: number;
}

function getInitialBoard(size: number): number[][] {
  let board: number[][] = [];
  let counter = 1;
  for (let i = 0; i < size; i++) {
    board[i] = [];
    for (let j = 0; j < size; j++) {
      board[i][j] = (i === size - 1 && j === size - 1) ? 0 : counter++;
    }
  }
  return board;
}

function copyBoard(source: number[][]): number[][] {
  return source.map(row => [...row]);
}

@Entry
@Component
struct HuarongGame {
  @State boardSize: number = 4;
  @State board: number[][] = getInitialBoard(4);
  @State gameWon: boolean = false;
  @State moveCount: number = 0;
  @State startTime: number = 0;
  @State timer: number = 0;
  private timerId: number = -1;
  @State clickedRow: number = -1;
  @State clickedCol: number = -1;
  @State refreshKey: number = 0;
  @State gameStarted: boolean = false;

  aboutToAppear(): void {
    this.startNewGame();
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) clearInterval(this.timerId);
  }

  setBoardSize(size: number): void {
    if (size === this.boardSize) return;
    this.boardSize = size;
    this.startNewGame();
  }

  findEmptyPosition(board: number[][]): Position {
    const size = board.length;
    for (let i = 0; i < size; i++) {
      for (let j = 0; j < size; j++) {
        if (board[i][j] === 0) return { row: i, col: j };
      }
    }
    return { row: -1, col: -1 };
  }

  getMovableNeighbors(row: number, col: number, board: number[][]): Position[] {
    const neighbors: Position[] = [];
    const dirs = [[-1,0],[1,0],[0,-1],[0,1]];
    const size = board.length;
    for (const d of dirs) {
      const nr = row + d[0], nc = col + d[1];
      if (nr>=0 && nr<size && nc>=0 && nc<size && board[nr][nc]!==0)
        neighbors.push({ row: nr, col: nc });
    }
    return neighbors;
  }

  startNewGame(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    let newBoard = getInitialBoard(this.boardSize);
    let emptyPos = this.findEmptyPosition(newBoard);
    for (let i = 0; i < SHUFFLE_MOVES; i++) {
      const neighbors = this.getMovableNeighbors(emptyPos.row, emptyPos.col, newBoard);
      if (neighbors.length > 0) {
        const rand = neighbors[Math.floor(Math.random() * neighbors.length)];
        newBoard[emptyPos.row][emptyPos.col] = newBoard[rand.row][rand.col];
        newBoard[rand.row][rand.col] = 0;
        emptyPos = rand;
      }
    }
    this.board = newBoard;
    this.gameWon = false;
    this.moveCount = 0;
    this.refreshKey++;
    this.gameStarted = false;
    this.startTime = 0;
    this.timer = 0;
    this.clickedRow = -1;
    this.clickedCol = -1;
  }

  tryMove(row: number, col: number): void {
    if (this.gameWon) return;
    const empty = this.findEmptyPosition(this.board);
    if (Math.abs(empty.row - row) + Math.abs(empty.col - col) !== 1) return;

    if (!this.gameStarted) {
      this.gameStarted = true;
      this.startTime = Date.now();
      this.timerId = setInterval(() => {
        this.timer = Math.floor((Date.now() - this.startTime) / 1000);
      }, 1000);
    }

    let newBoard = copyBoard(this.board);
    newBoard[empty.row][empty.col] = newBoard[row][col];
    newBoard[row][col] = 0;
    this.board = newBoard;
    this.moveCount++;
    this.refreshKey++;

    if (this.checkWin(this.board)) {
      this.gameWon = true;
      if (this.timerId !== -1) clearInterval(this.timerId);
      promptAction.showDialog({
        title: '胜利',
        message: `步数:${this.moveCount} 用时:${this.timer}秒`,
        buttons: [{ text: '再玩一局', color: '#007DFF' }]
      }).then(() => this.startNewGame()).catch((err: Error) => {
        console.error(`Dialog error: ${err.message}`);
        this.startNewGame();
      });
    }
  }

  checkWin(board: number[][]): boolean {
    const size = board.length;
    let expected = 1;
    for (let i = 0; i < size; i++)
      for (let j = 0; j < size; j++)
        if (i===size-1 && j===size-1) return board[i][j]===0;
        else if (board[i][j] !== expected++) return false;
    return false;
  }

  onGridClick(row: number, col: number): void {
    if (this.gameWon || this.board[row][col]===0) return;
    this.clickedRow = row; this.clickedCol = col;
    setTimeout(() => { this.clickedRow = -1; this.clickedCol = -1; }, 100);
    this.tryMove(row, col);
  }

  // 辅助方法：获取格子文本
  getCellText(row: number, col: number): string {
    const v = this.board[row][col];
    return v === 0 ? '' : v.toString();
  }

  // 辅助方法：获取背景色
  getCellBg(row: number, col: number): string {
    return this.board[row][col] === 0 ? '#F0F0F0' : '#007DFF';
  }

  // 辅助方法：获取文字颜色
  getCellColor(row: number, col: number): string {
    return this.board[row][col] === 0 ? '#FF9800' : '#FFFFFF';
  }

  // 辅助方法：获取缩放比例
  getCellScale(row: number, col: number): number {
    return (this.clickedRow === row && this.clickedCol === col) ? 0.9 : 1;
  }

  // 辅助方法：获取格子大小
  getCellSize(): number {
    if (this.boardSize === 3) return 90;
    if (this.boardSize === 4) return 80;
    return 65;
  }

  // 辅助方法：获取字体大小
  getFontSize(): number {
    if (this.boardSize === 3) return 32;
    if (this.boardSize === 4) return 28;
    return 20;
  }

  build() {
    Column() {
      Row() {
        Text(`步数: ${this.moveCount}`).fontSize(24).layoutWeight(1).textAlign(TextAlign.Center)
        Text(`用时: ${this.timer} s`).fontSize(24).layoutWeight(1).textAlign(TextAlign.Center)
        Button('重置').fontSize(20).layoutWeight(1).height(40).backgroundColor('#FF9800')
          .onClick(() => this.startNewGame())
      }
      .width('100%').padding(12).justifyContent(FlexAlign.SpaceEvenly)

      Row() {
        Text('难度：').fontSize(18).margin({ right: 10 })
        Radio({ value: '3', group: 'sizeGroup' }).checked(this.boardSize===3)
          .onChange((c: boolean) => { if(c) this.setBoardSize(3); })
        Text('3x3').fontSize(16).margin({ right: 20 })
        Radio({ value: '4', group: 'sizeGroup' }).checked(this.boardSize===4)
          .onChange((c: boolean) => { if(c) this.setBoardSize(4); })
        Text('4x4').fontSize(16).margin({ right: 20 })
        Radio({ value: '5', group: 'sizeGroup' }).checked(this.boardSize===5)
          .onChange((c: boolean) => { if(c) this.setBoardSize(5); })
        Text('5x5').fontSize(16)
      }
      .width('100%').padding(8).justifyContent(FlexAlign.Center)

      // 棋盘容器
      Column() {
        if (this.boardSize === 3) {
          Column() {
            Row() {
              Text(this.getCellText(0,0)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(0,0)).fontColor(this.getCellColor(0,0)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(0,0), y: this.getCellScale(0,0) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[0][0] !== 0) this.onGridClick(0,0); })
              Text(this.getCellText(0,1)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(0,1)).fontColor(this.getCellColor(0,1)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(0,1), y: this.getCellScale(0,1) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[0][1] !== 0) this.onGridClick(0,1); })
              Text(this.getCellText(0,2)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(0,2)).fontColor(this.getCellColor(0,2)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(0,2), y: this.getCellScale(0,2) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[0][2] !== 0) this.onGridClick(0,2); })
            }.justifyContent(FlexAlign.Center)
            Row() {
              Text(this.getCellText(1,0)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(1,0)).fontColor(this.getCellColor(1,0)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(1,0), y: this.getCellScale(1,0) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[1][0] !== 0) this.onGridClick(1,0); })
              Text(this.getCellText(1,1)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(1,1)).fontColor(this.getCellColor(1,1)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(1,1), y: this.getCellScale(1,1) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[1][1] !== 0) this.onGridClick(1,1); })
              Text(this.getCellText(1,2)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(1,2)).fontColor(this.getCellColor(1,2)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(1,2), y: this.getCellScale(1,2) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[1][2] !== 0) this.onGridClick(1,2); })
            }.justifyContent(FlexAlign.Center)
            Row() {
              Text(this.getCellText(2,0)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(2,0)).fontColor(this.getCellColor(2,0)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(2,0), y: this.getCellScale(2,0) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[2][0] !== 0) this.onGridClick(2,0); })
              Text(this.getCellText(2,1)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(2,1)).fontColor(this.getCellColor(2,1)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(2,1), y: this.getCellScale(2,1) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[2][1] !== 0) this.onGridClick(2,1); })
              Text(this.getCellText(2,2)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(2,2)).fontColor(this.getCellColor(2,2)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(2,2), y: this.getCellScale(2,2) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[2][2] !== 0) this.onGridClick(2,2); })
            }.justifyContent(FlexAlign.Center)
          }
        } else if (this.boardSize === 4) {
          Column() {
            Row() {
              Text(this.getCellText(0,0)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(0,0)).fontColor(this.getCellColor(0,0)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(0,0), y: this.getCellScale(0,0) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[0][0] !== 0) this.onGridClick(0,0); })
              Text(this.getCellText(0,1)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(0,1)).fontColor(this.getCellColor(0,1)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(0,1), y: this.getCellScale(0,1) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[0][1] !== 0) this.onGridClick(0,1); })
              Text(this.getCellText(0,2)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(0,2)).fontColor(this.getCellColor(0,2)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(0,2), y: this.getCellScale(0,2) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[0][2] !== 0) this.onGridClick(0,2); })
              Text(this.getCellText(0,3)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(0,3)).fontColor(this.getCellColor(0,3)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(0,3), y: this.getCellScale(0,3) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[0][3] !== 0) this.onGridClick(0,3); })
            }.justifyContent(FlexAlign.Center)
            Row() {
              Text(this.getCellText(1,0)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(1,0)).fontColor(this.getCellColor(1,0)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(1,0), y: this.getCellScale(1,0) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[1][0] !== 0) this.onGridClick(1,0); })
              Text(this.getCellText(1,1)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(1,1)).fontColor(this.getCellColor(1,1)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(1,1), y: this.getCellScale(1,1) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[1][1] !== 0) this.onGridClick(1,1); })
              Text(this.getCellText(1,2)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(1,2)).fontColor(this.getCellColor(1,2)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(1,2), y: this.getCellScale(1,2) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[1][2] !== 0) this.onGridClick(1,2); })
              Text(this.getCellText(1,3)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(1,3)).fontColor(this.getCellColor(1,3)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(1,3), y: this.getCellScale(1,3) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[1][3] !== 0) this.onGridClick(1,3); })
            }.justifyContent(FlexAlign.Center)
            Row() {
              Text(this.getCellText(2,0)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(2,0)).fontColor(this.getCellColor(2,0)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(2,0), y: this.getCellScale(2,0) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[2][0] !== 0) this.onGridClick(2,0); })
              Text(this.getCellText(2,1)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(2,1)).fontColor(this.getCellColor(2,1)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(2,1), y: this.getCellScale(2,1) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[2][1] !== 0) this.onGridClick(2,1); })
              Text(this.getCellText(2,2)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(2,2)).fontColor(this.getCellColor(2,2)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(2,2), y: this.getCellScale(2,2) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[2][2] !== 0) this.onGridClick(2,2); })
              Text(this.getCellText(2,3)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(2,3)).fontColor(this.getCellColor(2,3)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(2,3), y: this.getCellScale(2,3) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[2][3] !== 0) this.onGridClick(2,3); })
            }.justifyContent(FlexAlign.Center)
            Row() {
              Text(this.getCellText(3,0)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(3,0)).fontColor(this.getCellColor(3,0)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(3,0), y: this.getCellScale(3,0) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[3][0] !== 0) this.onGridClick(3,0); })
              Text(this.getCellText(3,1)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(3,1)).fontColor(this.getCellColor(3,1)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(3,1), y: this.getCellScale(3,1) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[3][1] !== 0) this.onGridClick(3,1); })
              Text(this.getCellText(3,2)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(3,2)).fontColor(this.getCellColor(3,2)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(3,2), y: this.getCellScale(3,2) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[3][2] !== 0) this.onGridClick(3,2); })
              Text(this.getCellText(3,3)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(3,3)).fontColor(this.getCellColor(3,3)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(3,3), y: this.getCellScale(3,3) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[3][3] !== 0) this.onGridClick(3,3); })
            }.justifyContent(FlexAlign.Center)
          }
        } else {
          Column() {
            Row() {
              Text(this.getCellText(0,0)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(0,0)).fontColor(this.getCellColor(0,0)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(0,0), y: this.getCellScale(0,0) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[0][0] !== 0) this.onGridClick(0,0); })
              Text(this.getCellText(0,1)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(0,1)).fontColor(this.getCellColor(0,1)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(0,1), y: this.getCellScale(0,1) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[0][1] !== 0) this.onGridClick(0,1); })
              Text(this.getCellText(0,2)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(0,2)).fontColor(this.getCellColor(0,2)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(0,2), y: this.getCellScale(0,2) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[0][2] !== 0) this.onGridClick(0,2); })
              Text(this.getCellText(0,3)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(0,3)).fontColor(this.getCellColor(0,3)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(0,3), y: this.getCellScale(0,3) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[0][3] !== 0) this.onGridClick(0,3); })
              Text(this.getCellText(0,4)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(0,4)).fontColor(this.getCellColor(0,4)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(0,4), y: this.getCellScale(0,4) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[0][4] !== 0) this.onGridClick(0,4); })
            }.justifyContent(FlexAlign.Center)
            Row() {
              Text(this.getCellText(1,0)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(1,0)).fontColor(this.getCellColor(1,0)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(1,0), y: this.getCellScale(1,0) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[1][0] !== 0) this.onGridClick(1,0); })
              Text(this.getCellText(1,1)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(1,1)).fontColor(this.getCellColor(1,1)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(1,1), y: this.getCellScale(1,1) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[1][1] !== 0) this.onGridClick(1,1); })
              Text(this.getCellText(1,2)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(1,2)).fontColor(this.getCellColor(1,2)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(1,2), y: this.getCellScale(1,2) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[1][2] !== 0) this.onGridClick(1,2); })
              Text(this.getCellText(1,3)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(1,3)).fontColor(this.getCellColor(1,3)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(1,3), y: this.getCellScale(1,3) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[1][3] !== 0) this.onGridClick(1,3); })
              Text(this.getCellText(1,4)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(1,4)).fontColor(this.getCellColor(1,4)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(1,4), y: this.getCellScale(1,4) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[1][4] !== 0) this.onGridClick(1,4); })
            }.justifyContent(FlexAlign.Center)
            Row() {
              Text(this.getCellText(2,0)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(2,0)).fontColor(this.getCellColor(2,0)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(2,0), y: this.getCellScale(2,0) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[2][0] !== 0) this.onGridClick(2,0); })
              Text(this.getCellText(2,1)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(2,1)).fontColor(this.getCellColor(2,1)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(2,1), y: this.getCellScale(2,1) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[2][1] !== 0) this.onGridClick(2,1); })
              Text(this.getCellText(2,2)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(2,2)).fontColor(this.getCellColor(2,2)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(2,2), y: this.getCellScale(2,2) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[2][2] !== 0) this.onGridClick(2,2); })
              Text(this.getCellText(2,3)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(2,3)).fontColor(this.getCellColor(2,3)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(2,3), y: this.getCellScale(2,3) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[2][3] !== 0) this.onGridClick(2,3); })
              Text(this.getCellText(2,4)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(2,4)).fontColor(this.getCellColor(2,4)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(2,4), y: this.getCellScale(2,4) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[2][4] !== 0) this.onGridClick(2,4); })
            }.justifyContent(FlexAlign.Center)
            Row() {
              Text(this.getCellText(3,0)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(3,0)).fontColor(this.getCellColor(3,0)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(3,0), y: this.getCellScale(3,0) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[3][0] !== 0) this.onGridClick(3,0); })
              Text(this.getCellText(3,1)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(3,1)).fontColor(this.getCellColor(3,1)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(3,1), y: this.getCellScale(3,1) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[3][1] !== 0) this.onGridClick(3,1); })
              Text(this.getCellText(3,2)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(3,2)).fontColor(this.getCellColor(3,2)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(3,2), y: this.getCellScale(3,2) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[3][2] !== 0) this.onGridClick(3,2); })
              Text(this.getCellText(3,3)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(3,3)).fontColor(this.getCellColor(3,3)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(3,3), y: this.getCellScale(3,3) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[3][3] !== 0) this.onGridClick(3,3); })
              Text(this.getCellText(3,4)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(3,4)).fontColor(this.getCellColor(3,4)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(3,4), y: this.getCellScale(3,4) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[3][4] !== 0) this.onGridClick(3,4); })
            }.justifyContent(FlexAlign.Center)
            Row() {
              Text(this.getCellText(4,0)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(4,0)).fontColor(this.getCellColor(4,0)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(4,0), y: this.getCellScale(4,0) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[4][0] !== 0) this.onGridClick(4,0); })
              Text(this.getCellText(4,1)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(4,1)).fontColor(this.getCellColor(4,1)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(4,1), y: this.getCellScale(4,1) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[4][1] !== 0) this.onGridClick(4,1); })
              Text(this.getCellText(4,2)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(4,2)).fontColor(this.getCellColor(4,2)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(4,2), y: this.getCellScale(4,2) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[4][2] !== 0) this.onGridClick(4,2); })
              Text(this.getCellText(4,3)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(4,3)).fontColor(this.getCellColor(4,3)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(4,3), y: this.getCellScale(4,3) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[4][3] !== 0) this.onGridClick(4,3); })
              Text(this.getCellText(4,4)).width(this.getCellSize()).height(this.getCellSize()).backgroundColor(this.getCellBg(4,4)).fontColor(this.getCellColor(4,4)).fontSize(this.getFontSize()).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).borderRadius(12).margin(2).scale({ x: this.getCellScale(4,4), y: this.getCellScale(4,4) }).animation({ duration: 100, curve: Curve.EaseInOut }).onClick(() => { if (!this.gameWon && this.board[4][4] !== 0) this.onGridClick(4,4); })
            }.justifyContent(FlexAlign.Center)
          }
        }
      }
      .width('100%')
      .backgroundColor('#FAFAFA')
      .borderRadius(20)
      .padding(10)
      .key(this.refreshKey.toString())
      .margin({ top: 10 })
      .alignItems(HorizontalAlign.Center)
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F5F5')
  }
}
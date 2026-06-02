import { promptAction } from '@kit.ArkUI';
import { window } from '@kit.ArkUI';

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
  @State containerWidth: number = 0;          // 棋盘容器实际宽度
  private boardPadding: number = 20;           // 内边距
  private cellMargin: number = 4;              // 格子外边距
  private maxBoardWidth: number = 600;         // 棋盘最大宽度限制（vp）

  aboutToAppear(): void {
    this.startNewGame();
    // 监听窗口大小变化，实现横竖屏自适应
    window.getLastWindow(getContext(this)).then((win) => {
      win.on('windowSizeChange', () => {
        // 窗口大小改变时，强制刷新 containerWidth（将在下一次 layout 中通过 onAreaChange 更新）
        this.containerWidth = 0;
      });
    });
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) clearInterval(this.timerId);
    // 移除窗口监听（可选，但组件销毁时自动清理）
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
      }).then(() => this.startNewGame()).catch(() => this.startNewGame());
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

  // 计算每个格子的宽度（限制最大棋盘宽度）
  getCellWidth(): number {
    if (this.containerWidth === 0) return 80;
    // 棋盘实际使用的宽度 = min(容器宽度, 最大宽度)
    const boardWidth = Math.min(this.containerWidth, this.maxBoardWidth);
    const available = boardWidth - this.boardPadding * 2;
    let cellW = available / this.boardSize - 2 * this.cellMargin;
    if (cellW < 50) cellW = 50;
    return cellW;
  }

  getFontSize(): number {
    return Math.max(16, this.getCellWidth() * 0.35);
  }

  // 辅助方法（供 @Builder 内部调用）
  getCellText(row: number, col: number): string {
    const v = this.board[row][col];
    return v === 0 ? '' : v.toString();
  }
  getCellBg(row: number, col: number): string {
    return this.board[row][col] === 0 ? '#F0F0F0' : '#007DFF';
  }
  getCellColor(row: number, col: number): string {
    return this.board[row][col] === 0 ? '#FF9800' : '#FFFFFF';
  }
  getCellScale(row: number, col: number): number {
    return (this.clickedRow === row && this.clickedCol === col) ? 0.9 : 1;
  }

  // 单个格子 @Builder
  @Builder
  Cell(row: number, col: number) {
    Text(this.getCellText(row, col))
      .width(this.getCellWidth())
      .height(this.getCellWidth())
      .backgroundColor(this.getCellBg(row, col))
      .fontColor(this.getCellColor(row, col))
      .fontSize(this.getFontSize())
      .fontWeight(FontWeight.Bold)
      .textAlign(TextAlign.Center)
      .borderRadius(12)
      .margin(this.cellMargin)
      .scale({
        x: this.getCellScale(row, col),
        y: this.getCellScale(row, col)
      })
      .animation({ duration: 100, curve: Curve.EaseInOut })
      .onClick(() => {
        if (!this.gameWon && this.board[row][col] !== 0) this.onGridClick(row, col);
      })
  }

  build() {
    Scroll() {
      Column() {
        // 顶部信息栏
        Row() {
          Text(`步数: ${this.moveCount}`).fontSize(24).layoutWeight(1).textAlign(TextAlign.Center)
          Text(`用时: ${this.timer} s`).fontSize(24).layoutWeight(1).textAlign(TextAlign.Center)
          Button('重置').fontSize(20).layoutWeight(1).height(40).backgroundColor('#FF9800')
            .onClick(() => this.startNewGame())
        }
        .width('100%').padding(12).justifyContent(FlexAlign.SpaceEvenly)

        // 难度选择
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

        // 棋盘容器（居中，限制最大宽度）
        Column() {
          if (this.boardSize === 3) {
            Column() {
              Row() { this.Cell(0,0); this.Cell(0,1); this.Cell(0,2); }.justifyContent(FlexAlign.Center)
              Row() { this.Cell(1,0); this.Cell(1,1); this.Cell(1,2); }.justifyContent(FlexAlign.Center)
              Row() { this.Cell(2,0); this.Cell(2,1); this.Cell(2,2); }.justifyContent(FlexAlign.Center)
            }
          } else if (this.boardSize === 4) {
            Column() {
              Row() { this.Cell(0,0); this.Cell(0,1); this.Cell(0,2); this.Cell(0,3); }.justifyContent(FlexAlign.Center)
              Row() { this.Cell(1,0); this.Cell(1,1); this.Cell(1,2); this.Cell(1,3); }.justifyContent(FlexAlign.Center)
              Row() { this.Cell(2,0); this.Cell(2,1); this.Cell(2,2); this.Cell(2,3); }.justifyContent(FlexAlign.Center)
              Row() { this.Cell(3,0); this.Cell(3,1); this.Cell(3,2); this.Cell(3,3); }.justifyContent(FlexAlign.Center)
            }
          } else {
            Column() {
              Row() { this.Cell(0,0); this.Cell(0,1); this.Cell(0,2); this.Cell(0,3); this.Cell(0,4); }.justifyContent(FlexAlign.Center)
              Row() { this.Cell(1,0); this.Cell(1,1); this.Cell(1,2); this.Cell(1,3); this.Cell(1,4); }.justifyContent(FlexAlign.Center)
              Row() { this.Cell(2,0); this.Cell(2,1); this.Cell(2,2); this.Cell(2,3); this.Cell(2,4); }.justifyContent(FlexAlign.Center)
              Row() { this.Cell(3,0); this.Cell(3,1); this.Cell(3,2); this.Cell(3,3); this.Cell(3,4); }.justifyContent(FlexAlign.Center)
              Row() { this.Cell(4,0); this.Cell(4,1); this.Cell(4,2); this.Cell(4,3); this.Cell(4,4); }.justifyContent(FlexAlign.Center)
            }
          }
        }
        .width('100%')
        .backgroundColor('#FAFAFA')
        .borderRadius(20)
        .padding(this.boardPadding)
        .key(this.refreshKey.toString())
        .margin({ top: 10, bottom: 20 })
        .alignItems(HorizontalAlign.Center)
        .onAreaChange((_: Area, newArea: Area) => {
          if (newArea.width && Math.abs(this.containerWidth - (newArea.width as number)) > 1) {
            this.containerWidth = newArea.width as number;
          }
        })
      }
      .width('100%')
    }
    .backgroundColor('#F5F5F5')
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }
}
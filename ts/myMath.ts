export class myMath {
    private _size: number = 0
    private _max: number = 0
    private _min: number = 0

    constructor(size: number, min: number, max: number) {
        this._size = size
        this._max = max
        this._min = min
    }

    private generateRandomNumber(): number {
        return Math.floor(Math.random() * (Math.ceil(this._max) - Math.floor(this._min)) + 1) + Math.floor(this._min)
    }

    generateRandomNumberSeries(): Array<number> {
        var randomList = new Array();
        var listSize: number = 0;

        while (listSize < this._size) {
            randomList.push(this.generateRandomNumber())
            listSize++
        }
        return randomList;
    }

    // 0,1,1,2,3,5,8...
    getFibanocciSeries(): Array<number> {
        var fib = new Array();
        var idx = 0;
        while (idx < this._size) {
            fib.push(this.getFibnumber(idx))
            idx++
        }
        return fib;
    }

    getFibnumber(atPosition: number): number {
        return atPosition < 2 ? 1 : this.getFibnumber(atPosition - 1) + this.getFibnumber(atPosition - 2)
    }

}
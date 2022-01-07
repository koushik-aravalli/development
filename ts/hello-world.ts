import { myMath } from "./myMath";

//async function getSum(params: Number[]) {
const getSum = async (params: Number[]) => {
    var total: number = 0;
    params.forEach(element => {
        total += element.valueOf()
    });
    return new Promise(resolve => resolve({ message: "elements: " + params + ", total: " + total }))
    // console.log("elements: " + params)
    // console.log("total: " + total)
}

// do sum of number in a list
let intlist = new Array();
for (var i = 0; i < 3; i++) {
    intlist.push(i)
}

// call async function and console log 
(async () => {
    console.log(await getSum(intlist));
}
)();

// create list with random numbers between a ceiling and floor
// var r = new myMath(5, 100, 50).generateRandomNumberSeries()
// console.log(r);

// return fibanocci series of size
var r = new myMath(15, 100, 50).getFibanocciSeries()
console.log(r);

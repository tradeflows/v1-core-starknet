import { expect } from "chai";
import { Bytes } from "ethers";

export function expectFeeEstimationStructure(fee: any) {
    console.log("Estimated fee:", fee);
    expect(fee).to.haveOwnProperty("amount");
    expect(typeof fee.amount).to.equal("bigint");
    expect(fee.unit).to.equal("wei");
}

// function string2Bin(str: string) {
//     var result = [];
//     for (var i = 0; i < str.length; i++) {
//       result.push(str.charCodeAt(i).toString(2));
//     }
//     return result;
// }

// export function string2Bin(str: string) {
//     var result = [];
//     for (var i = 0; i < str.length; i++) {
//         result.push(str.charCodeAt(i));
//     }
//     return result;
// }
  
// export function bin2String(array: number[]) {
//     return String.fromCharCode.apply(String, array);
// }

// export function str_to_felt(s: string){
//     // let charCodeArr = []
//     // for(let i = 0; i < s.length; i++){
//     //   let code = s.charCodeAt(i);
//     //   charCodeArr.push(code);
//     // }
    
//     // let _charCodeArr = Float32Array.from(charCodeArr)
//     let _charCodeArr = Float32Array.from(string2Bin(s))
  
//     const buf = Buffer.from(_charCodeArr)
    
//     return buf.readUInt32BE(0)
// }

// function getInt64Bytes( x: number ){
//     var bytes = [];
//     var i = 8;
//     do {
//     bytes[--i] = x & (255);
//     x = x>>8;
//     } while ( i )
//     return bytes;
// }

// function _bin2String(array: number[]) {
//     var result = "";
//     for (var i = 0; i < array.length; i++) {
//     //   result += String.fromCharCode(parseInt(array[i], 2));
//         result += String.fromCharCode(array[i]);
//     }
//     return result;
//   }

// export function felt_to_str(n: number){
//     return bin2String(getInt64Bytes(n))
// }
  
export function to_uint(a: bigint){
    return { low: 0n, high: a }
    // return { low: a, high: 0n }
}

export function from_uint(uint:any){
    return uint.low + uint.high
}
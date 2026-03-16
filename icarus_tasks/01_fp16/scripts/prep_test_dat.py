import numpy as np
from numpy.typing import NDArray
import sys

def _is_subnormal_f16(x: np.float16) -> bool:
    bits = x.view(np.uint16)
    exp = (bits >> 10) & 0x1F
    mant = bits & 0x3FF
    return exp == 0 and mant != 0


def _daz(x):
    if _is_subnormal_f16(x):
        return np.copysign(np.float16(0), x)
    return x


def _ftz(x):
    if _is_subnormal_f16(x):
        return np.copysign(np.float16(0), x)
    return x


def add_fp16_daz_ftz(a: np.float16, b: np.float16) -> np.float16:
    a = np.float16(a)
    b = np.float16(b)

    a = _daz(a)
    b = _daz(b)

    res = np.float16(a + b)
    # NumPy always uses round-to-nearest-even
    # it can cause sometimes the smallest normal
    # instead of a denormal

    res = _ftz(res)

    return res


def mul_fp16_daz_ftz(a: np.float16, b: np.float16) -> np.float16:
    a = np.float16(a)
    b = np.float16(b)

    a = _daz(a)
    b = _daz(b)

    res = np.float16(a * b)
    # NumPy always uses round-to-nearest-even
    # it can cause sometimes the smallest normal
    # instead of a denormal


    res = _ftz(res)

    return res

def generate_fp16_list(N: int) -> NDArray[np.float16]:
    ints = np.random.randint(0, 65536, size=N, dtype=np.uint16)
    floats = ints.view(np.float16)
    return floats


if __name__ == "__main__":
    np.random.seed(0)

    N = int(sys.argv[1])

    full = generate_fp16_list(2 * N)

    x_arr = full[0::2]
    y_arr = full[1::2]

    add_arr = np.array(
        [add_fp16_daz_ftz(x_arr[i], y_arr[i]) for i in range(N)],
        dtype=np.float16
    )

    mul_arr = np.array(
        [mul_fp16_daz_ftz(x_arr[i], y_arr[i]) for i in range(N)],
        dtype=np.float16
    )

    for x, y, add, mul in zip(x_arr, y_arr, add_arr, mul_arr):
        # print(x, y, add, mul)
        print(bytes(x)[::-1].hex(), 
              bytes(y)[::-1].hex(), 
              bytes(add)[::-1].hex(),
              bytes(mul)[::-1].hex(),
              sep='')

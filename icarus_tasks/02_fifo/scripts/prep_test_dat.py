import sys
import random
from collections import deque

def gen_test_data(N, depth, data_width):
    max_data = (1 << data_width) - 1
    queue = deque()  # Модель FIFO
    test_data = []

    for _ in range(N):
        empty = (len(queue) == 0)
        full = (len(queue) == depth)

        rd_en = random.randint(0, 1) if not empty else 0
        wr_en = random.randint(0, 1) if not full else 0

        wr_data = random.randint(0, max_data)

        rd_data = queue[0] if not empty else 0

        o_empty = 1 if empty else 0
        o_full = 1 if full else 0

        test_data.append((wr_data, rd_data, rd_en, wr_en, o_empty, o_full))

        if rd_en:
            queue.popleft()
        if wr_en:
            queue.append(wr_data)

    return test_data

def write_test_data(test_data, data_width):
    total_bits = 2 * data_width + 4
    hex_digits = (total_bits + 3) // 4

    for wr_data, rd_data, rd_en, wr_en, o_empty, o_full in test_data:
        flags = (rd_en << 3) | (wr_en << 2) | (o_empty << 1) | o_full
        packed = (wr_data << (data_width + 4)) | (rd_data << 4) | flags
        print(f"{packed:0{hex_digits}X}")

def main():
    if len(sys.argv) != 5:
        print(f"Usage: python3 {sys.argv[0]} N RAND_SEED DATAW LOG2DEPTH")
        sys.exit(1)

    N = int(sys.argv[1])
    RAND_SEED = int(sys.argv[2])
    DATAW = int(sys.argv[3])
    LOG2DEPTH = int(sys.argv[4])

    depth = 1 << LOG2DEPTH

    random.seed(RAND_SEED)

    test_data = gen_test_data(N, depth, DATAW)

    write_test_data(test_data, DATAW)

if __name__ == "__main__":
    main()



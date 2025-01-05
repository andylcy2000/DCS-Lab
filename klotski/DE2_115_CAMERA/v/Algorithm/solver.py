import numpy as np
from gif import write_gif
import matplotlib.pyplot as plt

#  0
# 2 3
#  1 

matrices = []

def find_number(klotski, number):
    for i in range(4):
        for j in range(4):
            if klotski[i][j] == number:
                return (i, j)
            
def check_move(mask, pos, direction, last_pos):
    if direction == 0:
        if (last_pos == [pos[0] - 1, pos[1]]):
            return False
        if pos[0] - 1 >= 0 and mask[pos[0] - 1][pos[1]] == 0:
            return True
    elif direction == 1:
        if (last_pos == [pos[0] + 1, pos[1]]):
            return False
        if pos[0] + 1 < 4 and mask[pos[0] + 1][pos[1]] == 0:
            return True
    elif direction == 2:
        if (last_pos == [pos[0], pos[1] - 1]):
            return False
        if pos[1] - 1 >= 0 and mask[pos[0]][pos[1] - 1] == 0:
            return True
    elif direction == 3:
        if (last_pos == [pos[0], pos[1] + 1]): 
            return False
        if pos[1] + 1 < 4 and mask[pos[0]][pos[1] + 1] == 0:
            return True
    return False

def move(klotski, pos, direction, last_pos, number_pos):
    if direction == 0:
        klotski[pos[0]][pos[1]] = klotski[pos[0] - 1][pos[1]]
        klotski[pos[0] - 1][pos[1]] = 0
        if (pos[0] == number_pos[0] or pos[1] == number_pos[1]):
            last_pos[0] = pos[0]
            last_pos[1] = pos[1]
        else:
            last_pos[0] = -1
            last_pos[1] = -1
    elif direction == 1:
        klotski[pos[0]][pos[1]] = klotski[pos[0] + 1][pos[1]]
        klotski[pos[0] + 1][pos[1]] = 0
        if (pos[0] == number_pos[0] or pos[1] == number_pos[1]):
            last_pos[0] = pos[0]
            last_pos[1] = pos[1]
        else:
            last_pos[0] = -1
            last_pos[1] = -1
    elif direction == 2:
        if (pos[0] == number_pos[0] or pos[1] == number_pos[1]):
            last_pos[0] = pos[0]
            last_pos[1] = pos[1]
        else:
            last_pos[0] = -1
            last_pos[1] = -1
        klotski[pos[0]][pos[1]] = klotski[pos[0]][pos[1] - 1]
        klotski[pos[0]][pos[1] - 1] = 0
    elif direction == 3:
        if (pos[0] == number_pos[0] or pos[1] == number_pos[1]):
            last_pos[0] = pos[0]
            last_pos[1] = pos[1]
        else:
            last_pos[0] = -1
            last_pos[1] = -1
        klotski[pos[0]][pos[1]] = klotski[pos[0]][pos[1] + 1]
        klotski[pos[0]][pos[1] + 1] = 0
    print(pos, last_pos)

def move_zero_to_target(klotski, mask, target, last_pos, number_pos, flag = False):
    zero_pos = find_number(klotski, 0)
    if (flag):
        if (zero_pos[0] <= target[0] and zero_pos[0] > number_pos[0]) and ((zero_pos[1] <= target[1] and zero_pos[1] >= number_pos[1]) or (zero_pos[1] >= target[1] and zero_pos[1] <= number_pos[1])):
            return
        if (zero_pos[1] <= target[1] and zero_pos[1] > number_pos[1]) and ((zero_pos[0] <= target[0] and zero_pos[0] >= number_pos[0]) or (zero_pos[0] >= target[0] and zero_pos[0] <= number_pos[0])):
            return
        if (zero_pos[0] >= target[0] and zero_pos[0] < number_pos[0]) and ((zero_pos[1] <= target[1] and zero_pos[1] >= number_pos[1]) or (zero_pos[1] >= target[1] and zero_pos[1] <= number_pos[1])):
            return
        if (zero_pos[1] >= target[1] and zero_pos[1] < number_pos[1]) and ((zero_pos[0] <= target[0] and zero_pos[0] >= number_pos[0]) or (zero_pos[0] >= target[0] and zero_pos[0] <= number_pos[0])):
            return
    if zero_pos[0] == target[0] and zero_pos[1] == target[1]:
        return
    check_up = check_move(mask, zero_pos, 0, last_pos)
    check_down = check_move(mask, zero_pos, 1, last_pos)
    check_left = check_move(mask, zero_pos, 2, last_pos)
    check_right = check_move(mask, zero_pos, 3, last_pos)
    dir = -1
    if zero_pos[0] < target[0]:
        if check_down:
            dir = 1
        elif zero_pos[1] < target[1]:
            if check_right:
                dir = 3
            elif check_left:
                dir = 2
            else:
                dir = 0
        elif zero_pos[1] > target[1]:
            if check_left:
                dir = 2
            elif check_up:
                dir = 0
            else:
                dir = 3
        else:
            if check_left:
                dir = 2
            elif check_right:
                dir = 3
            else:
                dir = 0
    elif zero_pos[0] > target[0]:
        if check_up:
            dir = 0
        elif zero_pos[1] < target[1]:
            if check_right:
                dir = 3
            elif check_down:
                dir = 1
            else:
                dir = 2
        elif zero_pos[1] > target[1]:
            if check_left:
                dir = 2
            elif check_right:
                dir = 3
            else:
                dir = 1
        else:
            if check_right:
                dir = 3
            elif check_left:
                dir = 2
            else:
                dir = 1
    else:
        if zero_pos[1] < target[1]:
            if check_right:
                dir = 3
            elif check_up:
                dir = 0
            elif check_down:
                dir = 1
            else:
                dir = 2
        else:
            if check_left:
                dir = 2
            elif check_up:
                dir = 0
            elif check_down:
                dir = 1
            else:
                dir = 3
    move(klotski, zero_pos, dir, last_pos, number_pos)
    matrices.append(klotski.copy())
    print(klotski, last_pos)
    print()
    move_zero_to_target(klotski, mask, target, last_pos, number_pos, flag)

def move_number_to_target(klotski, mask, target, number, last_pos):
    while True:
        number_pos = find_number(klotski, number)
        if (target == number_pos):
            break
        mask[number_pos[0]][number_pos[1]] = 1
        move_zero_to_target(klotski, mask, target, last_pos, number_pos, True)
        mask[number_pos[0]][number_pos[1]] = 0
        move_zero_to_target(klotski, mask, number_pos, last_pos, number_pos)
    mask[target[0]][target[1]] = 1

def solve(klotski):
    mask = np.zeros((4, 4))
    matrices.append(klotski.copy())
    last_pos = [-1, -1]
    move_number_to_target(klotski, mask, (0, 0), 1, last_pos)
    move_number_to_target(klotski, mask, (0, 1), 2, last_pos)
    move_number_to_target(klotski, mask, (3, 3), 4, last_pos)
    move_number_to_target(klotski, mask, (0, 3), 3, last_pos)
    move_number_to_target(klotski, mask, (1, 3), 4, last_pos)
    move_number_to_target(klotski, mask, (0, 2), 3, last_pos)
    move_number_to_target(klotski, mask, (0, 3), 4, last_pos)
    move_number_to_target(klotski, mask, (1, 0), 5, last_pos)
    move_number_to_target(klotski, mask, (1, 1), 6, last_pos)
    move_number_to_target(klotski, mask, (3, 3), 8, last_pos)
    pos = find_number(klotski, 8)
    mask[pos[0]][pos[1]] = 0
    last_pos = [-1, -1]
    move_number_to_target(klotski, mask, (1, 3), 7, last_pos)
    move_number_to_target(klotski, mask, (2, 3), 8, last_pos)
    move_number_to_target(klotski, mask, (1, 2), 7, last_pos)
    move_number_to_target(klotski, mask, (1, 3), 8, last_pos)
    move_number_to_target(klotski, mask, (3, 3), 13, last_pos)
    pos = find_number(klotski, 13)
    mask[pos[0]][pos[1]] = 0
    last_pos = [-1, -1]
    move_number_to_target(klotski, mask, (3, 0), 9, last_pos)
    move_number_to_target(klotski, mask, (3, 1), 13, last_pos)
    move_number_to_target(klotski, mask, (2, 0), 9, last_pos)
    move_number_to_target(klotski, mask, (3, 0), 13, last_pos)
    move_number_to_target(klotski, mask, (3, 3), 14, last_pos)
    pos = find_number(klotski, 14)
    mask[pos[0]][pos[1]] = 0
    last_pos = [-1, -1]
    move_number_to_target(klotski, mask, (3, 1), 10, last_pos)
    move_number_to_target(klotski, mask, (3, 2), 14, last_pos)
    move_number_to_target(klotski, mask, (2, 1), 10, last_pos)
    move_number_to_target(klotski, mask, (3, 1), 14, last_pos)
    move_number_to_target(klotski, mask, (2, 2), 11, last_pos)
    move_zero_to_target(klotski, mask, (3, 3), last_pos, [-1, -1])


def main():
    klotski = np.array([[10,  1, 14, 12],
                        [ 6,  2,  9, 15],
                        [ 3,  7,  5,  4],
                        [0, 11,  8,  13]])
    # generate a random klotski
    # klotski = np.random.permutation(16).reshape(4, 4)
    print(klotski)
    solve(klotski)
    print(klotski)
    # write_gif(matrices)

if __name__ == "__main__":
    main()

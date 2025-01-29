import numpy as np
import matplotlib.pyplot as plt
import random

beta_cc = 1.01e-5/24
Nc = 1
ticks = 50000

mu = 0.0039 / 24
phi = (mu**2) / (-1 + np.exp(-mu) + mu)

Ec_values = []
Ec = 0
Ic = 1

for x in range(ticks):
    dEc = phi * Ic - mu * Ec
    Ec += dEc
    Ec_values.append(Ec)


Pc_values = [1 - np.exp(-beta_cc * y / Nc) for y in Ec_values]


Pc_rounded = [round(Pc, 5) for Pc in Pc_values]

for x in range(len(Pc_rounded)):

    print("tick: {}, Ec: {}, Pc: {}, infected?: {}.".format(x,Ec_values[x],Pc_values[x], True if random.random() < Pc_values[x]  else False ))








plt.plot(Pc_rounded, marker='o', linestyle='-', color='b', label='Pc')
plt.title("probability of infection as Ec increases over time")
plt.xlabel("Index")
plt.ylabel("Value")
plt.legend()
plt.grid()
plt.show()

plt.plot(Ec_values, marker='o', linestyle='-', color='r', label='Ec')
plt.title("Environmental buildiup of btb overtime.")
plt.xlabel("Index")
plt.ylabel("Value")
plt.legend()
plt.grid()
plt.show()
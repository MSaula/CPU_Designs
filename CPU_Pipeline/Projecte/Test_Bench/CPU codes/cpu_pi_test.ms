ADDI 1 1 1     -- Sumem 1 al registre 1
ADDI 3 1 1     -- Posem un 2 al R3
NEG 2 1        -- Neguem el 1
MI2F 1 24      -- Passem el 1 a float al R24
MI2F 1 2       -- Passem el 1 a float al R2
MI2F 2 25      -- El R25 contindrà el -1 per fer multiplicacions
MI2F 3 26      -- El R26 contindrà el 2 per fer multiplicacions
FMULT 27 26 26 -- El R27 contindrà un 4
FMULT 27 27 25 -- El R27 contindrà un -4
FADD 1 1 24    -- Sumem 1 al R1 [El R1 és n]
FMULT 2 2 25   -- Multipliquem R2 per -1 [El R2 és (-1)^n]
FMULT 3 1 26   -- Multipliquem n*2
FSUB 3 3 24    --  Restem 1 a 2n
FMULT 4 2 27   -- Multipliquem (-1)^2 * -4 (així el resultat final es pi i no -pi/4)
FDIV 9 4 3     -- Fem la divisió final
FADD 10 10 9   -- Acumulem a R10 (on el valor anirà aproximant-se a pi)
JMP -7         -- Tornem a l'inici del bucle

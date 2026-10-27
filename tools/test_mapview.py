from mapview import parse_rows, picture

text = """; header
;      row  0  not a map row (column 0)
demo
    ; row 0: top
    .BYTE EMP,BRA   ; cols 0-1
    .BYTE WNL       ; cols 2
    ; row 1
    .BYTE FLW,EMP,XYZ
"""
rows = parse_rows(text)
assert rows == [["EMP", "BRA", "WNL"], ["FLW", "EMP", "XYZ"]]   # rows span lines; header comment ignored
assert picture(rows)[-2:] == ["row  0    .A[", "row  1    _.?"]    # unknown tile -> ?
print("ok")

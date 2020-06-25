import sys


if __name__ == '__main__':
  first_line = True
  CSV_AS_MATRIX = []
  for line in sys.stdin:
    if first_line:
      first_line = False
      continue
    
    CSV_AS_MATRIX.append(
      [ float(x) if '[' not in x else float(x.split(' ')[0]) for x in line.split(',')[2:] ]
    )

  print('x,c2sJavaNormal,c2sJavaAug,c2sJavaAdvRand,c2sJavaAdvGrad,csnJavaNormal,csnJavaAug,csnJavaAdvRand,csnJavaAdvGrad,csnPythonNormal,csnPythonAug,csnPythonAdvRand,csnPythonAdvGrad,sriPythonNormal,sriPythonAug,sriPythonAdvRand,sriPythonAdvGrad')
  
  idx = 1
  for i in [0, 1, 3, 2, 4]:
    print("{},{}".format(
      idx,
      ",".join([ '{:.1f}'.format(x) for x in [ 
        CSV_AS_MATRIX[0][0+i],
        CSV_AS_MATRIX[1][0+i],
        CSV_AS_MATRIX[2][0+i],
        CSV_AS_MATRIX[3][0+i],
        CSV_AS_MATRIX[0][5+i],
        CSV_AS_MATRIX[1][5+i],
        CSV_AS_MATRIX[2][5+i],
        CSV_AS_MATRIX[3][5+i],
        CSV_AS_MATRIX[0][10+i],
        CSV_AS_MATRIX[1][10+i],
        CSV_AS_MATRIX[2][10+i],
        CSV_AS_MATRIX[3][10+i],
        CSV_AS_MATRIX[0][15+i],
        CSV_AS_MATRIX[1][15+i],
        CSV_AS_MATRIX[2][15+i],
        CSV_AS_MATRIX[3][15+i]
      ]])
    ))
    idx += 1

    # print("{},{}".format(
    #   i+1,
    #   ",".join([ '{:.1f}'.format(x) for x in [ 
    #     CSV_AS_MATRIX[0][0+i],
    #     (CSV_AS_MATRIX[1][0+i] - CSV_AS_MATRIX[0][0+i]) / CSV_AS_MATRIX[0][0+i] * 100.0,
    #     (CSV_AS_MATRIX[2][0+i] - CSV_AS_MATRIX[0][0+i]) / CSV_AS_MATRIX[0][0+i] * 100.0,
    #     (CSV_AS_MATRIX[3][0+i] - CSV_AS_MATRIX[0][0+i]) / CSV_AS_MATRIX[0][0+i] * 100.0,
    #     CSV_AS_MATRIX[0][5+i],
    #     (CSV_AS_MATRIX[1][5+i] - CSV_AS_MATRIX[0][5+i]) / CSV_AS_MATRIX[0][5+i] * 100.0,
    #     (CSV_AS_MATRIX[2][5+i] - CSV_AS_MATRIX[0][5+i]) / CSV_AS_MATRIX[0][5+i] * 100.0,
    #     (CSV_AS_MATRIX[3][5+i] - CSV_AS_MATRIX[0][5+i]) / CSV_AS_MATRIX[0][5+i] * 100.0,
    #     CSV_AS_MATRIX[0][10+i],
    #     (CSV_AS_MATRIX[1][10+i] - CSV_AS_MATRIX[0][10+i]) / CSV_AS_MATRIX[0][10+i] * 100.0,
    #     (CSV_AS_MATRIX[2][10+i] - CSV_AS_MATRIX[0][10+i]) / CSV_AS_MATRIX[0][10+i] * 100.0,
    #     (CSV_AS_MATRIX[3][10+i] - CSV_AS_MATRIX[0][10+i]) / CSV_AS_MATRIX[0][10+i] * 100.0,
    #     CSV_AS_MATRIX[0][15+i],
    #     (CSV_AS_MATRIX[1][15+i] - CSV_AS_MATRIX[0][15+i]) / CSV_AS_MATRIX[0][15+i] * 100.0,
    #     (CSV_AS_MATRIX[2][15+i] - CSV_AS_MATRIX[0][15+i]) / CSV_AS_MATRIX[0][15+i] * 100.0,
    #     (CSV_AS_MATRIX[3][15+i] - CSV_AS_MATRIX[0][15+i]) / CSV_AS_MATRIX[0][15+i] * 100.0
    #   ]])
    # ))

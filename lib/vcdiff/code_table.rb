module VCDIFF
  # Default code table as defined in RFC 3284 (5.6)
  # 
  #       TYPE      SIZE     MODE    TYPE     SIZE     MODE     INDEX
  #      ---------------------------------------------------------------
  #   1.  RUN         0        0     NOOP       0        0        0
  #   2.  ADD    0, [1,17]     0     NOOP       0        0      [1,18]
  #   3.  COPY   0, [4,18]     0     NOOP       0        0     [19,34]
  #   4.  COPY   0, [4,18]     1     NOOP       0        0     [35,50]
  #   5.  COPY   0, [4,18]     2     NOOP       0        0     [51,66]
  #   6.  COPY   0, [4,18]     3     NOOP       0        0     [67,82]
  #   7.  COPY   0, [4,18]     4     NOOP       0        0     [83,98]
  #   8.  COPY   0, [4,18]     5     NOOP       0        0     [99,114]
  #   9.  COPY   0, [4,18]     6     NOOP       0        0    [115,130]
  #  10.  COPY   0, [4,18]     7     NOOP       0        0    [131,146]
  #  11.  COPY   0, [4,18]     8     NOOP       0        0    [147,162]
  #  12.  ADD       [1,4]      0     COPY     [4,6]      0    [163,174]
  #  13.  ADD       [1,4]      0     COPY     [4,6]      1    [175,186]
  #  14.  ADD       [1,4]      0     COPY     [4,6]      2    [187,198]
  #  15.  ADD       [1,4]      0     COPY     [4,6]      3    [199,210]
  #  16.  ADD       [1,4]      0     COPY     [4,6]      4    [211,222]
  #  17.  ADD       [1,4]      0     COPY     [4,6]      5    [223,234]
  #  18.  ADD       [1,4]      0     COPY       4        6    [235,238]
  #  19.  ADD       [1,4]      0     COPY       4        7    [239,242]
  #  20.  ADD       [1,4]      0     COPY       4        8    [243,246]
  #  21.  COPY        4      [0,8]   ADD        1        0    [247,255]
  #      ---------------------------------------------------------------
  class CodeTable
    NOOP, ADD, RUN, COPY = 0, 1, 2, 3

    DEFAULT_TABLE = [
      [RUN, 0, 0, NOOP, 0, 0],
    ]
    
    (0..17).each do |n|
      DEFAULT_TABLE << [ADD, n, 0, NOOP, 0, 0]
    end
    
    (0..8).each do |mode|
      DEFAULT_TABLE << [COPY, 0, mode, NOOP, 0, 0]
      
      (4..18).each do |size|
        DEFAULT_TABLE << [COPY, size, mode, NOOP, 0, 0]
      end
    end
    
    (0..5).each do |mode|
      (1..4).each do |add_size|
        (4..6).each do |copy_size|
          DEFAULT_TABLE << [ADD, add_size, 0, COPY, copy_size, mode]
        end
      end
    end
    
    (6..8).each do |mode|
      (1..4).each do |add_size|
        DEFAULT_TABLE << [ADD, add_size, 0, COPY, 4, mode]
      end
    end
    
    (0..8).each do |mode|
      DEFAULT_TABLE << [COPY, 4, mode, ADD, 1, 0]
    end
  end
end

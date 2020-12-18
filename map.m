% --------------------------------------------------------------------
%
% Helper function for mapping two arrays onto each other
% input_len: length of array indexed with index
% output_len: length of array indexed with outdex
% index: index of element for input array
% returns: index of element for output array
%
% --------------------------------------------------------------------

function outdex = map(input_len, output_len, index)
  outdex = 1 + ((output_len - 1) / (input_len - 1)) * (index - 1);
  outdex = floor(outdex);
end
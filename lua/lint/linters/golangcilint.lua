local severities = {
  error = vim.lsp.protocol.DiagnosticSeverity.Error,
  warning = vim.lsp.protocol.DiagnosticSeverity.Warning,
  refactor = vim.lsp.protocol.DiagnosticSeverity.Information,
  convention = vim.lsp.protocol.DiagnosticSeverity.Hint,
}

return {
  cmd = 'golangci-lint',
  stdin = true,
  args = {
    'run',
    '--out-format',
    'json',
  },
  stream = 'stdout',
  ignore_exitcode = true,
  parser = function(output, bufnr)
    if output == '' then
      return {}
    end
    local decoded = vim.fn.json_decode(output)
    if decoded["Issues"] == nil or type(decoded["Issues"]) == 'userdata' then
      return {}
    end

    local group_diagnostics = {}
    for _, item in ipairs(decoded["Issues"]) do
      local sv = vim.lsp.protocol.DiagnosticSeverity.Warning
      if severities[item.Severity] ~= nil then
        sv = severities[item.Severity]
      end
      local fl = 'file://' .. vim.fn.getcwd() .. '/' .. item.Pos.Filename
      local diag = {
        range = {
          ['start'] = {
            line = item.Pos.Line - 1,
            character = item.Pos.Column - 1,
          },
          ['end'] = {
            line = item.Pos.Line - 1,
            character = item.Pos.Column - 1,
          },
          ['filename'] = item.Pos.Filename,
        },
        severity = sv,
        message = item.Text,
        source = "golangci-lint",
     }

      if group_diagnostics[fl] == nil then group_diagnostics[fl] = {} end
      table.insert(group_diagnostics[fl], diag)
    end

    return {multiple = true, diagnostics = group_diagnostics}
  end
}

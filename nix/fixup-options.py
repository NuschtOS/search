#!/usr/bin/env python
import sys
import json
import markdown
from pygments import highlight
from pygments.lexers import NixLexer
from pygments.formatters import HtmlFormatter
from html_sanitizer import Sanitizer

sanitizer = Sanitizer()

if (len(sys.argv) - 1) % 2 != 0:
  print("Usage: path/to/options.json https://example.com/option/ path/to/other/options.json https://example.com/other_option/")
  sys.exit(1)

def code(code):
  if code["_type"] == 'literalExpression':
    return highlight(code["text"], NixLexer(), HtmlFormatter())
  elif code["_type"] == 'literalMD':
    return sanitizer.sanitize(markdown.markdown(code["text"]))
  else:
    print("ERROR: cannot handle a " + code["_type"], file=sys.stderr)
    sys.exit(1)


def update_declaration(url, declaration):
  if "url" in declaration:
    return declaration["url"]
  if declaration.startswith("/nix/store/"):
    # strip prefix: /nix/store/0a0mxyfmad6kaknkkr0ysraifws856i7-source
    return f"{url}{declaration[51:]}"
  return declaration

out = []

for i in range(1,len(sys.argv),2):
  with open(sys.argv[i], "r", encoding="utf-8") as file:
    url = sys.argv[i+1]
    data = json.load(file)

    for key in data:
      entry = data[key]
      entry["name"] = key
      del entry["loc"]
      entry["declarations"] = list(map(lambda x: update_declaration(url, x), entry["declarations"]))

      entry["description"] = sanitizer.sanitize(markdown.markdown(entry["description"]))
      if 'default' in entry:
        entry['default'] = code(entry["default"])
      if 'example' in entry:
        entry['example'] = code(entry["example"])
      out.append(entry)


print(json.dumps(out))

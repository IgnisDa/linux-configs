from libqtile.config import Group, Match

groups = []

group_names = [
    {'label': 'Terminal', 'name': 1,
     'matches': [Match(wm_class=['kitty'])]},
    {'label': 'Browser', 'name': 2,
     'matches': [Match(wm_class=['qutebrowser'])]},
    {'label': 'Editor',  'name': 3,
     'matches': [Match(wm_class=['code-oss'])]},
    {'label': 'File Manager', 'name': 4,
     'matches': [Match(wm_class=['file-manager'])]},
    {'label': 'College', 'name': 5,
     'matches': [Match(wm_class=['notion', 'microsoft teams - preview'])]},
]

for option in group_names:
    name = option.pop('name')
    groups.append(Group(str(name), **option))

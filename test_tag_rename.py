#!/usr/bin/python3

import tag_rename

def assert_eq(expected, actual):
    if expected != actual:
        raise AssertionError(
                'Expected "'
                + str(expected)
                + '", was "'
                + str(actual)
                + '"')

def test_simplify():
    testcases = {
            '.,:;"?!\' \t()/\\+': '_______',
            'årets största räkning[]{}': 'arets_storsta_rakning____',
            'Some stupid song!': 'some_stupid_song'
    }
    for k, v in testcases.items():
        assert_eq(v, tag_rename.simplify(k))

def test_generate_file_name():
    testcases = {
            (('TRACKNUMBER', '2'),
                ('TITLE', 'Le Song')) : '02-le_song.flac',
            (('TRACKNUMBER', '30'),
                ('TITLE', 'Le Other Song')) :  '30-le_other_song.flac',
            (('TRACKNUMBER', 'Ingen titel=krasch'),) : AssertionError,
            (('TITLE', 'Inget nummeer=krasch'),) : AssertionError
    }
    for k, v in testcases.items():
        try:
            assert_eq(v, tag_rename.generate_file_name({t[0]: t[1] for t in k}))
        except v:
            pass

def test_generate_dir_name():
    testcases = {
            (
                ('fil1', ('ARTIST', 'Nisse'), ('ALBUM', 'Bleh')),
                ('fil2', ('ARTIST', 'Nisse'), ('ALBUM', 'Bleh')))
            : 'nisse-bleh',
            (
                ('fil1', ('ARTIST', 'Nisse'), ('ALBUM', 'Bleh')),
                ('fil2', ('ARTIST', 'Nisse'), ('ALBUM', 'Bleh')),
                ('fil2', ('ARTIST', 'Beatles'), ('ALBUM', 'The White Album')))
            : AssertionError,
    }
    for k, v in testcases.items():
        try:
            tag_dict = {}
            for fil in k:
                tag_dict[fil[0]] = {t[0]: t[1] for t in fil[1:]}
            assert_eq(v, tag_rename.generate_dir_name(tag_dict))
        except v:
            pass

def test_parse_tags():
    testcases = {
            'ARTIST=Nisse\nALBUM=Bleh\nGENRE=Trancecore': {
                'ARTIST': 'Nisse',
                'ALBUM': 'Bleh',
                'GENRE': 'Trancecore'},
            'Artist=Nisse\nAlbum=Bleh\nGenre=Trancecore\n\n': {
                'ARTIST': 'Nisse',
                'ALBUM': 'Bleh',
                'GENRE': 'Trancecore'}
    }
    for k, v in testcases.items():
        try:
            assert_eq(v, tag_rename.parse_tags(k))
        except v:
            pass


if __name__ == '__main__':
    test_simplify()
    test_generate_file_name()
    test_generate_dir_name()
    test_parse_tags()

{ pkgs, ... }:

{
  home.packages = [ pkgs.kanata ];

  xdg.configFile."kanata/config.kbd".text = ''
    (defcfg
        process-unmapped-keys yes
        concurrent-tap-hold yes
    )

    (defvar
        tap-time 1
        hold-time 500
    )

    (defalias
        caps (tap-hold 100 100 esc lctl)
    ;;  a    (tap-hold $tap-time $hold-time a lmet)
    ;;  s    (tap-hold $tap-time $hold-time s lalt)
    ;;  d    (tap-hold $tap-time $hold-time d lsft)
    ;;  f    (tap-hold $tap-time $hold-time f lctl)
    ;;  j    (tap-hold $tap-time $hold-time j rctl)
    ;;  k    (tap-hold $tap-time $hold-time k rsft)
    ;;  l    (tap-hold $tap-time $hold-time l ralt)
    ;;  ;    (tap-hold $tap-time $hold-time ; rmet)
    )

    ;; Keyboard KS70 without the macros keys
    (defsrc
        esc    1    2    3    4    5    6    7    8    9    0    -    =    bspc    `
        tab    q    w    e    r    t    y    u    i    o    p    [    ]    \       del
        caps   a    s    d    f    g    h    j    k    l    ;    '       ret       pgup
        lsft   z    x    c    v    b    n    m    ,    .    /      rsft      up    pgdn
        lctl   lmet lalt           spc            ralt     rctl    left    down    rght
    )

    (deflayer base
        esc    1    2    3    4    5    6    7    8    9    0    -    =    bspc    `
        tab    q    w    e    r    t    y    u    i    o    p    [    ]    \       del
        @caps  a    s    d    f    g    h    j    k    l    ;    '       ret       pgup
        lsft   z    x    c    v    b    n    m    ,    .    /      rsft      up    pgdn
        lctl   lmet lalt           spc            ralt     rctl    left    down    rght
    )

    ;; Disable harcoded hardware macros for RKS70
    (defchordsv2
        (lctl a) () 2 all-released ()
        (lctl c) () 2 all-released ()
        (lctl v) () 2 all-released ()
        (lctl x) () 2 all-released ()
        (lctl s) () 2 all-released ()
    )
  '';
}

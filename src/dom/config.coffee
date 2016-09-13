module.exports =
    # Global settings

    # The CSS class names used when an element is drag aligned to the left or
    # right of another element.
    ALIGNMENT_CLASS_NAMES: {
        'left': 'align-left',
        'right': 'align-right'
    }

    # The default min/max constraints (in pixels) for element that can be
    # resized (`ContentEdit.ResizableElement`). The default values are used when
    # a min/max width has not been set using the custom attributes
    # `data-ce-max-width` and `data-ce-min-width`.
    DEFAULT_MAX_ELEMENT_WIDTH: 800
    DEFAULT_MIN_ELEMENT_WIDTH: 80

    # Some elements such as images are dragged simply by clicking on them and
    # moving the mouse. Others like text handle click events differently (for
    # example focusing the element so text can be edited), these element support
    # dragging behaviour when a user clicks and holds (without moving the
    # mouse). The duration of the hold is determined in milliseconds.
    DRAG_HOLD_DURATION: 500

    # The size (in pixels) of the edges used to switch horizontal placement
    # (e.g drop left/right) when dragging an element over another (for
    # example an image being dragged to the right edge of a text element).
    DROP_EDGE_SIZE: 50

    # The maximum number of characters to insert into a helper (for example the
    # helper tool that appears when dragging elements).
    HELPER_CHAR_LIMIT: 250

    # String to use for a single indent. For example if you wanted html to
    # return HTML indented using tabs instead of spaces you could set this to
    # `\t`.
    INDENT: '    '

    # The current language. Must be a a 2 digit ISO_639-1 code.
    LANGUAGE: 'en'

    # By default a new paragraph `<p>` is created when the enter/return key is
    # pressed, to insert a line-break `<br>` the shift key can be held down when
    # pressing enter. This behaviour can be reversed by setting the preference
    # to be for line-breaks.
    PREFER_LINE_BREAKS: false

    # The size (in pixels) of the corner region used to detect a resize event
    # against an element. To resize an element (for example an image or video)
    # the user must click in a corner region of an element. The size is
    # automatically reduced for small elements where the corner size represents
    # more than a 1/4 of the total size.
    RESIZE_CORNER_SIZE: 15

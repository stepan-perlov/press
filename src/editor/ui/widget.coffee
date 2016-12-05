View = require("./view.coffee")

class Widget extends View

    # The widget class provides a base class for components that render at the
    # root of the application.

    attach: (component, index) ->
        # Attach a component as a child of this component
        super(component, index)

        if not @isMounted()
            component.mount()

    detatch: (component) ->
        # Detach a child component from this component
        super(component)

        if @isMounted()
            component.unmount()

    show: () ->
        # Show the widget
        if not @isMounted()
            @mount()

        # We delay adding the --active modifier to ensure any CSS transition is
        # activated.
        fadeIn = () =>
            @addCSSClass('ct-widget--active')

        setTimeout(fadeIn, 100)

    hide: () ->
        # Hide the widget

        # Removing the --active modifier will attempt to trigger an CSS
        # transition to fade out the widget. Once the transition to 0 opacity
        # is complete we unmount it.
        @removeCSSClass('ct-widget--active')

        monitorForHidden = () =>

            # If there's no support for `getComputedStyle` then we fallback to
            # unmounting the widget immediately.
            unless window.getComputedStyle
                @unmount()
                return

            # If the widget is now hidden we unmount it
            if parseFloat(window.getComputedStyle(@_domElement).opacity) < 0.01
                @unmount()
            else
                setTimeout(monitorForHidden, 250)

        if @isMounted()
            setTimeout(monitorForHidden, 250)

module.exports = Widget

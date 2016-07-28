###
# Copyright 2015-2016 ppy Pty. Ltd.
#
# This file is part of osu!web. osu!web is distributed with the hope of
# attracting more community contributions to the core ecosystem of osu!.
#
# osu!web is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License version 3
# as published by the Free Software Foundation.
#
# osu!web is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with osu!web.  If not, see <http://www.gnu.org/licenses/>.
###
class @Nav
  constructor: ->
    $(document).on 'mouseenter', '.js-nav-popup', @showPopup
    $(document).on 'mouseleave', '.js-nav-popup', @gracefulHidePopup
    $(document).on 'click', @hidePopup

    $(document).on 'click', '.js-nav-toggle', @toggleMenu
    $(document).on 'click', '.js-nav-switch', @switchMode
    $(window).on 'throttled-scroll throttled-resize', @repositionPopup
    $(document).on 'transitionend', '.js-nav-popup--container', @reset
    $(document).on 'turblinks:load', @syncAll

    @popup = document.getElementsByClassName('js-nav-popup--popup')
    @popupContainer = document.getElementsByClassName('js-nav-popup--container')
    @menus = document.getElementsByClassName('js-nav-switch--menu')
    @switches = document.getElementsByClassName('js-nav-switch')
    @floatBeacon = document.getElementsByClassName('js-nav-popup--beacon')


  autoFocus: (e, popup) =>
    return if !@data().visible

    if e?
      popup = e.currentTarget

    return if popup.dataset.navMode != @currentMode()

    popup.getElementsByClassName('js-nav-auto-focus')[0]?.focus?()


  available: => @popup[0]?


  currentMode: =>
    @data().currentMode ?= 'default'


  currentSubMode: =>
    @data().currentSubMode


  data: =>
    @popup[0]?.dataset


  floatPopup: (float) =>
    if float
      @popupContainer[0].style.position = 'fixed'
      @popupContainer[0].style.width = '100%'
    else
      @popupContainer[0].style.position = ''


  gracefulHidePopup: =>
    return if @currentMode() != 'default'
    @hidePopup()


  hidePopup: (e) =>
    return if !@available()
    return if !@data().visible

    if e?
      return if $(e.target).closest('.js-nav-popup').length != 0

    Timeout.clear @hideTimeout
    @hideTimeout = Timeout.set 10, =>
      @showAllMenu false
      $.publish 'nav:popup:hidden'


  repositionPopup: =>
    return if !@available()
    return if !@data().visible

    beaconPosition = @floatBeacon[0].getBoundingClientRect()

    float = beaconPosition.bottom < 0
    @floatPopup float


  reset: =>
    return if @data().visible

    @setMode()
    @floatPopup false


  setMode: (modeHash = {}) =>
    return if !@available()

    newMode = modeHash.navMode ? modeHash.mode ? 'default'
    newSubMode = modeHash.navSubMode ? modeHash.subMode ? ''

    updated = true

    if newMode != @data().currentMode
      @data().currentMode = newMode
      @data().currentSubMode = newSubMode
    else if newSubMode != @data().currentSubMode
      @data().currentSubMode = newSubMode
    else
      updated = false

    @syncMode() if updated
    updated


  showAllMenu: (enable) =>
    @data().visible = if enable then '1' else ''

    @syncMenu()


  showPopup: =>
    return if !@available()

    Timeout.clear @hideTimeout
    @showAllMenu true
    @repositionPopup()


  switchMode: (e) =>
    if e?
      e.preventDefault()

      modeHash = e.currentTarget.dataset
      modeHash = null if @currentMode() == modeHash.navMode

    @setMode modeHash


  syncAll: =>
    @syncMenu()
    @syncMode()


  syncMenu: =>
    for menu in @menus
      if @data().visible
        menu.classList.add 'js-nav-switch--visible'
      else
        menu.classList.remove 'js-nav-switch--visible'


  syncMode: =>
    animateClass = 'js-nav-switch--animated'
    activeClass = 'js-nav-switch--active'

    for menu in @menus
      if @data().visible
        menu.classList.add animateClass
      else
        menu.classList.remove animateClass

      if menu.dataset.navMode == @currentMode()
        menu.classList.add activeClass

        for submenu in menu.getElementsByClassName('js-nav-popup--submenu')
          if !@currentSubMode() || submenu.dataset.navSubMode == @currentSubMode()
            submenu.classList.remove 'hidden'
          else
            submenu.classList.add 'hidden'

        if menu.classList.contains 'js-nav-switch--animated'
          $(menu)
            .off 'transitionend', @autoFocus
            .one 'transitionend', @autoFocus
        else
          Timeout.set 0, => @autoFocus null, menu

      else
        menu.classList.remove activeClass

    for link in @switches
      isCurrent =
        link.dataset.navMode == @currentMode() &&
        (!@currentSubMode() || link.dataset.navSubMode == @currentSubMode())

      if isCurrent
        link.classList.add activeClass
      else
        link.classList.remove activeClass


  toggleMenu: (e) =>
    e.preventDefault()
    e.stopPropagation()

    if @setMode e.currentTarget.dataset
      @showPopup() unless @data().visible
    else
      @hidePopup()

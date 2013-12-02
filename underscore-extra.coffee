entryMap =
  escape:
    '&': '&amp;'
    '<': '&lt;'
    '>': '&gt;'
    '"': '&quot;'
    "'": '&#x27;'
    '/': '&#x2F;'

entryMap.unescape = _.invert entryMap.escape
difference = _.difference

# chainable
_.mixin
  # utils [[[
  mixPatch: (map) ->
    _(map).chain()
      .keys()
      .filter (key) ->
        key not in _.keys _
      .map (key) ->
        _.mixin _(map).pick key
        key
      .value()

  swap: (obj, propertys) ->
    obj = _.clone obj
    [first, last] = propertys
    [obj[first], obj[last]] = [obj[last], obj[first]]
    obj

  ###
    _(obj).chain()
      .batch("isFunction", "isString") // [true, false]
      .some()
  ###
  batch: (obj, methods...) ->
    return obj if _.isEmpty methods
    _.map methods, (method) -> _.result obj, method

  ###
    _.batchIf([
      function (name, value) { return this[name] == null },
      function (name, value) { return this[name] === value }
    ], {args: ["a", 1], context: {a: 2}}) // => false
  ###
  batchIf: (exprs, options={}) ->
    {args, context} = options
    _(exprs).chain()
      .map (expr) ->
        if _.isFunction expr
          expr.apply(context, args)
        else
          expr
      .every((result) -> !!result)
      .value()

  ###
    handlerMap = {
      "true": function() {
        alert("a")
        return "b"
      },
      "b": "b"
    }

    obj = {
      "b": function(m) {
        console.log(m)
        return "c"
      },
      "c": 3
    }

    _([1, 0]).chain()
      .every()
      .disjunctor(handlerMap) // alert "a"
      .disjunctor(handlerMap, {context: obj, args: ["b"]}) // console "b"
      .disjunctor(handlerMap, {context: obj})
      .value() // => 3
  ###
  disjunctor: (signal, handlerMap, options={}) ->
    return unless handler = handlerMap[signal]
    {context, args} = options
    _.result context, handler, args

  ###
    get obj result
      _.resultWithArgs obj, (false || '' || null || undefined), [args...], context
    get obj.fn or obj.fn(args...) result
      _.resultWithArgs obj, 'fn', [args...], context
  ###
  resultWithArgs: (obj, property, args, context) ->
    return unless obj?
    value = if property? then obj[property] else obj
    context = obj unless context?
    args = [args] unless _.isArray args
    return value unless _.isFunction value
    value.apply context, args
  # ]]]

  # patch [[[
  difference: (array, others..., deep) ->
    if not deep or _.isArray deep
      return difference.apply _, [array].concat(others).concat [deep]
    rest = _.flatten others, true
    _.filter array, (value) ->
      not _.some rest, (part) -> _.isEqual part, value

  escape: (string, ignoreChar=[]) ->
    return '' unless string?
    keys = _.keys entryMap.escape
    _.each ignoreChar, (char) -> _.arrayDel keys, char, true
    ('' + string).replace ///[#{keys.join ''}]///g, (match) ->
      entryMap.escape[match]

  unescape: (string, ignoreChar=[]) ->
    return '' unless string?
    keys = _.keys entryMap.escape
    _.each ignoreChar, (char) -> _.arrayDel keys, entryMap.escape[char], true
    ('' + string).replace ///[#{keys.join ''}]///g, (match) ->
      entryMap.unescape[match]

  property: _.result

  result: (object, property, args, context) ->
    return unless arguments.length
    if arguments.length is 1
      if _.isFunction(object) then object() else object
    if arguments.length is 2
      _.property object, property
    else if _.isFunction property
      property.apply (context or object), args
    else
      _.resultWithArgs object, property, args, context

  # ]]]

  # collection [[[
  pack: (obj) ->
    return obj unless _.isObject obj
    return obj unless _.every obj, (value) -> _.isArray value
    result = []
    _.forEach obj, (vals, key) ->
      _.forEach vals, (value, index) ->
        result[index] or= if _.isArray(obj) then [] else {}
        result[index][key] = value
    result

  deleteWhere: (coll, filter, destructive) ->
    _.arrayDel coll, filter, {destructive, findByAttrs: true}

  split: (obj, spliter) ->
    return obj.split(spliter) if _.isString obj
    return [] unless _.isArray obj
    memo = []
    cloneThis = _.clone obj
    cloneThis.push spliter
    _(cloneThis).chain().map (elem) ->
      if _.isEqual elem, spliter
        [clone, memo] = [memo, []]
        return clone
      else
        memo.push elem
        return
    .filter (elem) ->
      elem? and elem.length
    .value()
  # ]]]

  # array [[[
  walk: (array, property, callback, thisArg) ->
    return unless _.isArray array
    return unless property

    callback ?= _.identity

    _.forEach array, (elem) ->
      callback.call thisArg, elem, array
      _.walk elem[property], property, callback, thisArg

  # option = {
  #   destructive: '是否直接作用在array上，默认为false',
  #   findByAttrs: '是否调用findIndex来获取元素的index，默认为false'
  # }
  arrayDel: (array, elem, option = {}) ->
    return array unless _.isArray array
    option = destructive: option if _.isBoolean option
    elemIndex = _[if option.findByAttrs then 'findIndex' else 'indexOf'] array, elem
    return array if elemIndex is -1
    newArray = if option.destructive then array else array.slice()
    newArray.splice elemIndex, 1
    newArray
  # ]]]

# unchainable
_.mixin
  # collection [[[
  in: (elem, obj) ->
    return false unless elem?
    return false unless obj?
    obj = _.result obj
    if $.isPlainObject obj
      obj[elem]?
    else if _.isArray(obj) or _.isString(obj)
      !!~_.indexOf obj, elem
    else
      false
  # ]]]

  # object [[[
  isDigit: (obj) ->
    return unless obj
    obj = obj.toString()
    obj = obj.slice(1) if obj.charAt(0) is '-'
    /^\d+$/.test obj

  hasProp: (obj, props, some) ->
    _(props).chain()
      .map(_.partial _.has, obj)
      .resultWithArgs((if some then "some" else "every"), _.identity)
      .value()
  # ]]]

  # array [[[
  sum: (array) ->
    return unless _.isArray array
    _.reduce array, (result, number) ->
      result + number
  # ]]]

, {chain: false}

# patch
_.mixPatch
  findIndex: (array, callback, thisArg) ->
    return -1 unless _.isArray array
    callback ?= _.identity

    if _.isFunction callback
      _.forEach array, (elem, index) ->
        return index if callback.call thisArg, elem
      -1
    else if _.isObject callback
      _.indexOf array, _.findWhere array, callback
    else
      _.pluck array, callback


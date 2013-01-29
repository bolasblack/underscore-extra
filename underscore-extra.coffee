entryMap =
  escape:
    '&': '&amp;'
    '<': '&lt;'
    '>': '&gt;'
    '"': '&quot;'
    "'": '&#x27;'
    '/': '&#x2F;'

entryMap.unescape = _.invert entryMap.escape

_.mixin

  # collection [[[
  in: (elem, obj) ->
    return false unless elem?
    return false unless obj?
    _elem = _ elem
    _obj = _ _(obj).result()
    if $.isPlainObject obj
      obj[elem]?
    else if _obj.isArray() or _obj.isString()
      !!~_obj.indexOf elem
    else
      false

  deleteWhere: (coll, filter) ->
    if _(filter).isArray()
      _(filter).forEach (f) ->
        coll = _(coll).deleteWhere f
    else
      _(coll).chain().where(filter).forEach (atom) ->
        coll = _(coll).arrayDel atom
    coll

  split: (obj, spliter) ->
    return obj.split(spliter) if _.isString obj
    return [] unless _.isArray obj
    memo = []
    cloneThis = _(obj).clone()
    cloneThis.push spliter
    _(cloneThis).chain().map (elem) ->
      if _(elem).isEqual spliter
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
  sum: (array) ->
    _array = _ array
    return unless _array.isArray()
    _array.reduce (result, number) ->
      result + number

  arrayDel: (array, obj) ->
    index = _(array).indexOf obj
    return if !~index
    newArray = _.clone array
    newArray.splice index, 1
    newArray
  # ]]]

  # object [[[
  isDigit: (obj) -> /^\d+$/.test obj.toString()

  hasProp: (obj, attrList, some) ->
    _(attrList).chain()
      .map (attr) ->
        _(obj).has(attr) and obj[attr]?
      .resultWithArgs((if some then "some" else "every"), [_.identity])
      .value()

  swap: (obj, propertys) ->
    obj = _.clone obj
    [first, last] = propertys
    [obj[first], obj[last]] = [obj[last], obj[first]]
    obj
  # ]]]

  # utils [[[
  escape: (string, ignoreChar=[]) ->
    return '' unless string?
    keys = _(entryMap.escape).keys()
    _(ignoreChar).each (char) -> keys = _(keys).arrayDel char
    ('' + string).replace ///[#{keys.join ''}]///g, (match) ->
      entryMap.escape[match]

  unescape: (string, ignoreChar=[]) ->
    return '' unless string?
    keys = _(entryMap.escape).keys()
    _(ignoreChar).each (char) -> keys = _(keys).arrayDel entryMap.escape[char]
    ('' + string).replace ///[#{keys.join ''}]///g, (match) ->
      entryMap.unescape[match]

  ###
    _(obj).chain()
      .batch("isFunction", "isString") // [true, false]
      .some()
  ###
  batch: (obj, methods...) ->
    return obj if _(methods).isEmpty()
    _(methods).map (method) -> _(obj).result method

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
        if _(expr).isFunction()
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
    _(context).result handler, args

  property: _.result

  ###
    get obj result
      _.resultWithArgs obj, undefined, [args...], context
    get obj[fn] result
      _.resultWithArgs obj, fn, [args...], context
  ###
  resultWithArgs: (obj, property, args, context) ->
    return unless obj?
    value = if property? then obj[property] else obj
    context ?= obj if property?
    return value unless _.isFunction value
    value.apply context, args

  result: (object, property, args, context) ->
    return unless arguments.length
    if arguments.length is 1
      if _(object).isFunction() then object() else object
    if arguments.length is 2
      _.property object, property
    else if _(property).isFunction()
      property.apply (context or object), args
    else
      _.resultWithArgs object, property, args, context
  # ]]]

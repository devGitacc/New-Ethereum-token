jQuery ->

  az = web3?

  debug = true

  get_campaigns = () ->
    campaigns_data = web3.db.getString('etherstarter', 'campaigns')
    if(campaigns_data == '')
      []
    else
      JSON.parse(campaigns_data)

  add_campaign = (campaign) ->
    campaigns = get_campaigns()
    campaigns.push(campaign)
    web3.db.putString('etherstarter', 'campaigns', JSON.stringify(campaigns))

  subscribe_whisper = () ->
    shh.watch(
      topic: [
        web3.fromAscii('etherstarter')
        web3.fromAscii(contract)
        web3.fromAscii('announce-campaign')
      ]
    ).arrived (msg) ->
      campaign = JSON.parse(web3.toAscii(msg.payload))
      #alert('WHISPER RECEIVED ' + response.description)
      add_campaign(campaign)
      #campaigns = web3.db.getString('etherstarter', 'campaigns')
      #alert(campaigns)

  post_whisper = (id, title, description) ->
    payload = web3.fromAscii(JSON.stringify({id: id, title: title, description: description}))
    shh.post
      topic: [
        web3.fromAscii('etherstarter')
        web3.fromAscii(contract)
        web3.fromAscii('announce-campaign')
      ]
      payload: payload
      ttl: 600

  if(az)
    shh = web3.shh
    contract = web3.db.get('etherstarter', 'contract')
    abi = JSON.parse(web3.db.getString('etherstarter', 'abi'))
    crowdfund = web3.eth.contract(contract, abi)
    subscribe_whisper()

  set_campaign_in_ui = (campaigns, id) ->
    campaign = $.grep campaigns, (e) ->
      return e.id == id
    campaign = campaigns[0]
    $('.title h1').text(campaign.title)
    $('.description').text(campaign.description)

    recipient = crowdfund.call().get_recipient(id)

    # if recipient == 0

    goal = crowdfund.call().get_goal(id)
    deadline = crowdfund.call().get_deadline(id)
    progress = crowdfund.call().get_total(id)

  if($('body.home').length > 0)

    selector = $('select#campaigns')
    campaigns = get_campaigns()

    $.each campaigns, (index, campaign) ->
      if(index == 0)
        set_campaign_in_ui(campaigns, campaign.id)

      selector.append($('<option/>', {
        value: campaign.id,
        text : campaign.title
      }))

    selector.on 'change', (e) ->
      id = selector.val()
      set_campaign(campaigns, id)



  # ADMIN

  if($('body.admin').length > 0)

    if(debug)
      $('#create_campaign').show()
      $('#title').val('Title')
      $('#description').val('Description')
      $('#goal').val('500')
      $('#duration').val('10')
      $('#recipient').val('dedc82cb364f93ddec1bf323069951b91c75c591')

    form = $('#create_campaign form')

    form.on 'submit', (e) ->
      e.preventDefault()

      title = form.find('#title').val()
      description = form.find('#description').val()
      goal = +form.find('#goal').val()
      deadline = (Date.now() / 1000) + +form.find('#duration').val()*24*60*60
      recipient = '0x' + form.find('#recipient').val()

      if(az)
        id = crowdfund.call().get_free_id()
        retval = crowdfund.transact().create_campaign(id, recipient, goal, deadline, 0, 0)
        post_whisper(id, title, description)
        #alert(crowdfund.call().get_recipient(id))


    $('#create_campaign a#close').on 'click', (e) ->
      e.preventDefault()
      $('#create_campaign').hide()
      $('a#create_new_campaign').show()

    $('#create_new_campaign').on 'click', (e) ->
      e.preventDefault()

      $(this).hide()
      $('#create_campaign').fadeIn()

      form.find('#title').focus()

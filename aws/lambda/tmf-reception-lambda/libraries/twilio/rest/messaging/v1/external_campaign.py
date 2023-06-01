# coding=utf-8
r"""
This code was generated by
\ / _    _  _|   _  _
 | (_)\/(_)(_|\/| |(/_  v1.0.0
      /       /
"""

from twilio.base import deserialize
from twilio.base import values
from twilio.base.instance_resource import InstanceResource
from twilio.base.list_resource import ListResource
from twilio.base.page import Page


class ExternalCampaignList(ListResource):
    """ PLEASE NOTE that this class contains beta products that are subject to
    change. Use them with caution. """

    def __init__(self, version):
        """
        Initialize the ExternalCampaignList

        :param Version version: Version that contains the resource

        :returns: twilio.rest.messaging.v1.external_campaign.ExternalCampaignList
        :rtype: twilio.rest.messaging.v1.external_campaign.ExternalCampaignList
        """
        super(ExternalCampaignList, self).__init__(version)

        # Path Solution
        self._solution = {}
        self._uri = '/Services/PreregisteredUsa2p'.format(**self._solution)

    def create(self, campaign_id, messaging_service_sid):
        """
        Create the ExternalCampaignInstance

        :param unicode campaign_id: ID of the preregistered campaign.
        :param unicode messaging_service_sid: The SID of the Messaging Service the resource is associated with

        :returns: The created ExternalCampaignInstance
        :rtype: twilio.rest.messaging.v1.external_campaign.ExternalCampaignInstance
        """
        data = values.of({'CampaignId': campaign_id, 'MessagingServiceSid': messaging_service_sid, })

        payload = self._version.create(method='POST', uri=self._uri, data=data, )

        return ExternalCampaignInstance(self._version, payload, )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        return '<Twilio.Messaging.V1.ExternalCampaignList>'


class ExternalCampaignPage(Page):
    """ PLEASE NOTE that this class contains beta products that are subject to
    change. Use them with caution. """

    def __init__(self, version, response, solution):
        """
        Initialize the ExternalCampaignPage

        :param Version version: Version that contains the resource
        :param Response response: Response from the API

        :returns: twilio.rest.messaging.v1.external_campaign.ExternalCampaignPage
        :rtype: twilio.rest.messaging.v1.external_campaign.ExternalCampaignPage
        """
        super(ExternalCampaignPage, self).__init__(version, response)

        # Path Solution
        self._solution = solution

    def get_instance(self, payload):
        """
        Build an instance of ExternalCampaignInstance

        :param dict payload: Payload response from the API

        :returns: twilio.rest.messaging.v1.external_campaign.ExternalCampaignInstance
        :rtype: twilio.rest.messaging.v1.external_campaign.ExternalCampaignInstance
        """
        return ExternalCampaignInstance(self._version, payload, )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        return '<Twilio.Messaging.V1.ExternalCampaignPage>'


class ExternalCampaignInstance(InstanceResource):
    """ PLEASE NOTE that this class contains beta products that are subject to
    change. Use them with caution. """

    def __init__(self, version, payload):
        """
        Initialize the ExternalCampaignInstance

        :returns: twilio.rest.messaging.v1.external_campaign.ExternalCampaignInstance
        :rtype: twilio.rest.messaging.v1.external_campaign.ExternalCampaignInstance
        """
        super(ExternalCampaignInstance, self).__init__(version)

        # Marshaled Properties
        self._properties = {
            'sid': payload.get('sid'),
            'account_sid': payload.get('account_sid'),
            'campaign_id': payload.get('campaign_id'),
            'messaging_service_sid': payload.get('messaging_service_sid'),
            'date_created': deserialize.iso8601_datetime(payload.get('date_created')),
        }

        # Context
        self._context = None
        self._solution = {}

    @property
    def sid(self):
        """
        :returns: The unique string that identifies a US A2P Compliance resource
        :rtype: unicode
        """
        return self._properties['sid']

    @property
    def account_sid(self):
        """
        :returns: The SID of the Account that created the resource
        :rtype: unicode
        """
        return self._properties['account_sid']

    @property
    def campaign_id(self):
        """
        :returns: ID of the preregistered campaign.
        :rtype: unicode
        """
        return self._properties['campaign_id']

    @property
    def messaging_service_sid(self):
        """
        :returns: The SID of the Messaging Service the resource is associated with
        :rtype: unicode
        """
        return self._properties['messaging_service_sid']

    @property
    def date_created(self):
        """
        :returns: The ISO 8601 date and time in GMT when the resource was created
        :rtype: datetime
        """
        return self._properties['date_created']

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        return '<Twilio.Messaging.V1.ExternalCampaignInstance>'

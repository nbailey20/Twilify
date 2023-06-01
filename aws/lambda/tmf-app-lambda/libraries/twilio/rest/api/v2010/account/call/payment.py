# coding=utf-8
r"""
This code was generated by
\ / _    _  _|   _  _
 | (_)\/(_)(_|\/| |(/_  v1.0.0
      /       /
"""

from twilio.base import deserialize
from twilio.base import serialize
from twilio.base import values
from twilio.base.instance_context import InstanceContext
from twilio.base.instance_resource import InstanceResource
from twilio.base.list_resource import ListResource
from twilio.base.page import Page


class PaymentList(ListResource):
    """ PLEASE NOTE that this class contains preview products that are subject
    to change. Use them with caution. If you currently do not have developer
    preview access, please contact help@twilio.com. """

    def __init__(self, version, account_sid, call_sid):
        """
        Initialize the PaymentList

        :param Version version: Version that contains the resource
        :param account_sid: The SID of the Account that created the Payments resource.
        :param call_sid: The SID of the Call the resource is associated with.

        :returns: twilio.rest.api.v2010.account.call.payment.PaymentList
        :rtype: twilio.rest.api.v2010.account.call.payment.PaymentList
        """
        super(PaymentList, self).__init__(version)

        # Path Solution
        self._solution = {'account_sid': account_sid, 'call_sid': call_sid, }
        self._uri = '/Accounts/{account_sid}/Calls/{call_sid}/Payments.json'.format(**self._solution)

    def create(self, idempotency_key, status_callback,
               bank_account_type=values.unset, charge_amount=values.unset,
               currency=values.unset, description=values.unset, input=values.unset,
               min_postal_code_length=values.unset, parameter=values.unset,
               payment_connector=values.unset, payment_method=values.unset,
               postal_code=values.unset, security_code=values.unset,
               timeout=values.unset, token_type=values.unset,
               valid_card_types=values.unset):
        """
        Create the PaymentInstance

        :param unicode idempotency_key: A unique token that will be used to ensure that multiple API calls with the same information do not result in multiple transactions.
        :param unicode status_callback: Provide an absolute or relative URL to receive status updates regarding your Pay session..
        :param PaymentInstance.BankAccountType bank_account_type: Type of bank account if payment source is ACH.
        :param unicode charge_amount: A positive decimal value less than 1,000,000 to charge against the credit card or bank account.
        :param unicode currency: The currency of the `charge_amount`.
        :param unicode description: The description can be used to provide more details regarding the transaction.
        :param unicode input: A list of inputs that should be accepted. Currently only `dtmf` is supported.
        :param unicode min_postal_code_length: A positive integer that is used to validate the length of the `PostalCode` inputted by the user.
        :param dict parameter: A single level JSON string that is required when accepting certain information specific only to ACH payments.
        :param unicode payment_connector: This is the unique name corresponding to the Payment Gateway Connector installed in the Twilio Add-ons.
        :param PaymentInstance.PaymentMethod payment_method: Type of payment being captured.
        :param bool postal_code: Indicates whether the credit card PostalCode (zip code) is a required piece of payment information that must be provided by the caller.
        :param bool security_code: Indicates whether the credit card security code is a required piece of payment information that must be provided by the caller.
        :param unicode timeout: The number of seconds that <Pay> should wait for the caller to press a digit between each subsequent digit, after the first one, before moving on to validate the digits captured.
        :param PaymentInstance.TokenType token_type: Indicates whether the payment method should be tokenized as a `one-time` or `reusable` token.
        :param unicode valid_card_types: Credit card types separated by space that Pay should accept.

        :returns: The created PaymentInstance
        :rtype: twilio.rest.api.v2010.account.call.payment.PaymentInstance
        """
        data = values.of({
            'IdempotencyKey': idempotency_key,
            'StatusCallback': status_callback,
            'BankAccountType': bank_account_type,
            'ChargeAmount': charge_amount,
            'Currency': currency,
            'Description': description,
            'Input': input,
            'MinPostalCodeLength': min_postal_code_length,
            'Parameter': serialize.object(parameter),
            'PaymentConnector': payment_connector,
            'PaymentMethod': payment_method,
            'PostalCode': postal_code,
            'SecurityCode': security_code,
            'Timeout': timeout,
            'TokenType': token_type,
            'ValidCardTypes': valid_card_types,
        })

        payload = self._version.create(method='POST', uri=self._uri, data=data, )

        return PaymentInstance(
            self._version,
            payload,
            account_sid=self._solution['account_sid'],
            call_sid=self._solution['call_sid'],
        )

    def get(self, sid):
        """
        Constructs a PaymentContext

        :param sid: The SID of Payments session

        :returns: twilio.rest.api.v2010.account.call.payment.PaymentContext
        :rtype: twilio.rest.api.v2010.account.call.payment.PaymentContext
        """
        return PaymentContext(
            self._version,
            account_sid=self._solution['account_sid'],
            call_sid=self._solution['call_sid'],
            sid=sid,
        )

    def __call__(self, sid):
        """
        Constructs a PaymentContext

        :param sid: The SID of Payments session

        :returns: twilio.rest.api.v2010.account.call.payment.PaymentContext
        :rtype: twilio.rest.api.v2010.account.call.payment.PaymentContext
        """
        return PaymentContext(
            self._version,
            account_sid=self._solution['account_sid'],
            call_sid=self._solution['call_sid'],
            sid=sid,
        )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        return '<Twilio.Api.V2010.PaymentList>'


class PaymentPage(Page):
    """ PLEASE NOTE that this class contains preview products that are subject
    to change. Use them with caution. If you currently do not have developer
    preview access, please contact help@twilio.com. """

    def __init__(self, version, response, solution):
        """
        Initialize the PaymentPage

        :param Version version: Version that contains the resource
        :param Response response: Response from the API
        :param account_sid: The SID of the Account that created the Payments resource.
        :param call_sid: The SID of the Call the resource is associated with.

        :returns: twilio.rest.api.v2010.account.call.payment.PaymentPage
        :rtype: twilio.rest.api.v2010.account.call.payment.PaymentPage
        """
        super(PaymentPage, self).__init__(version, response)

        # Path Solution
        self._solution = solution

    def get_instance(self, payload):
        """
        Build an instance of PaymentInstance

        :param dict payload: Payload response from the API

        :returns: twilio.rest.api.v2010.account.call.payment.PaymentInstance
        :rtype: twilio.rest.api.v2010.account.call.payment.PaymentInstance
        """
        return PaymentInstance(
            self._version,
            payload,
            account_sid=self._solution['account_sid'],
            call_sid=self._solution['call_sid'],
        )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        return '<Twilio.Api.V2010.PaymentPage>'


class PaymentContext(InstanceContext):
    """ PLEASE NOTE that this class contains preview products that are subject
    to change. Use them with caution. If you currently do not have developer
    preview access, please contact help@twilio.com. """

    def __init__(self, version, account_sid, call_sid, sid):
        """
        Initialize the PaymentContext

        :param Version version: Version that contains the resource
        :param account_sid: The SID of the Account that will update the resource
        :param call_sid: The SID of the call that will create the resource.
        :param sid: The SID of Payments session

        :returns: twilio.rest.api.v2010.account.call.payment.PaymentContext
        :rtype: twilio.rest.api.v2010.account.call.payment.PaymentContext
        """
        super(PaymentContext, self).__init__(version)

        # Path Solution
        self._solution = {'account_sid': account_sid, 'call_sid': call_sid, 'sid': sid, }
        self._uri = '/Accounts/{account_sid}/Calls/{call_sid}/Payments/{sid}.json'.format(**self._solution)

    def update(self, idempotency_key, status_callback, capture=values.unset,
               status=values.unset):
        """
        Update the PaymentInstance

        :param unicode idempotency_key: A unique token that will be used to ensure that multiple API calls with the same information do not result in multiple transactions.
        :param unicode status_callback: Provide an absolute or relative URL to receive status updates regarding your Pay session.
        :param PaymentInstance.Capture capture: The piece of payment information that you wish the caller to enter.
        :param PaymentInstance.Status status: Indicates whether the current payment session should be cancelled or completed.

        :returns: The updated PaymentInstance
        :rtype: twilio.rest.api.v2010.account.call.payment.PaymentInstance
        """
        data = values.of({
            'IdempotencyKey': idempotency_key,
            'StatusCallback': status_callback,
            'Capture': capture,
            'Status': status,
        })

        payload = self._version.update(method='POST', uri=self._uri, data=data, )

        return PaymentInstance(
            self._version,
            payload,
            account_sid=self._solution['account_sid'],
            call_sid=self._solution['call_sid'],
            sid=self._solution['sid'],
        )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        context = ' '.join('{}={}'.format(k, v) for k, v in self._solution.items())
        return '<Twilio.Api.V2010.PaymentContext {}>'.format(context)


class PaymentInstance(InstanceResource):
    """ PLEASE NOTE that this class contains preview products that are subject
    to change. Use them with caution. If you currently do not have developer
    preview access, please contact help@twilio.com. """

    class PaymentMethod(object):
        CREDIT_CARD = "credit-card"
        ACH_DEBIT = "ach-debit"

    class BankAccountType(object):
        CONSUMER_CHECKING = "consumer-checking"
        CONSUMER_SAVINGS = "consumer-savings"
        COMMERCIAL_CHECKING = "commercial-checking"

    class TokenType(object):
        ONE_TIME = "one-time"
        REUSABLE = "reusable"

    class Capture(object):
        PAYMENT_CARD_NUMBER = "payment-card-number"
        EXPIRATION_DATE = "expiration-date"
        SECURITY_CODE = "security-code"
        POSTAL_CODE = "postal-code"
        BANK_ROUTING_NUMBER = "bank-routing-number"
        BANK_ACCOUNT_NUMBER = "bank-account-number"

    class Status(object):
        COMPLETE = "complete"
        CANCEL = "cancel"

    def __init__(self, version, payload, account_sid, call_sid, sid=None):
        """
        Initialize the PaymentInstance

        :returns: twilio.rest.api.v2010.account.call.payment.PaymentInstance
        :rtype: twilio.rest.api.v2010.account.call.payment.PaymentInstance
        """
        super(PaymentInstance, self).__init__(version)

        # Marshaled Properties
        self._properties = {
            'account_sid': payload.get('account_sid'),
            'call_sid': payload.get('call_sid'),
            'sid': payload.get('sid'),
            'date_created': deserialize.rfc2822_datetime(payload.get('date_created')),
            'date_updated': deserialize.rfc2822_datetime(payload.get('date_updated')),
            'uri': payload.get('uri'),
        }

        # Context
        self._context = None
        self._solution = {
            'account_sid': account_sid,
            'call_sid': call_sid,
            'sid': sid or self._properties['sid'],
        }

    @property
    def _proxy(self):
        """
        Generate an instance context for the instance, the context is capable of
        performing various actions.  All instance actions are proxied to the context

        :returns: PaymentContext for this PaymentInstance
        :rtype: twilio.rest.api.v2010.account.call.payment.PaymentContext
        """
        if self._context is None:
            self._context = PaymentContext(
                self._version,
                account_sid=self._solution['account_sid'],
                call_sid=self._solution['call_sid'],
                sid=self._solution['sid'],
            )
        return self._context

    @property
    def account_sid(self):
        """
        :returns: The SID of the Account that created the Payments resource.
        :rtype: unicode
        """
        return self._properties['account_sid']

    @property
    def call_sid(self):
        """
        :returns: The SID of the Call the resource is associated with.
        :rtype: unicode
        """
        return self._properties['call_sid']

    @property
    def sid(self):
        """
        :returns: The SID of the Payments resource.
        :rtype: unicode
        """
        return self._properties['sid']

    @property
    def date_created(self):
        """
        :returns: The RFC 2822 date and time in GMT that the resource was created
        :rtype: datetime
        """
        return self._properties['date_created']

    @property
    def date_updated(self):
        """
        :returns: The RFC 2822 date and time in GMT that the resource was last updated
        :rtype: datetime
        """
        return self._properties['date_updated']

    @property
    def uri(self):
        """
        :returns: The URI of the resource, relative to `https://api.twilio.com`
        :rtype: unicode
        """
        return self._properties['uri']

    def update(self, idempotency_key, status_callback, capture=values.unset,
               status=values.unset):
        """
        Update the PaymentInstance

        :param unicode idempotency_key: A unique token that will be used to ensure that multiple API calls with the same information do not result in multiple transactions.
        :param unicode status_callback: Provide an absolute or relative URL to receive status updates regarding your Pay session.
        :param PaymentInstance.Capture capture: The piece of payment information that you wish the caller to enter.
        :param PaymentInstance.Status status: Indicates whether the current payment session should be cancelled or completed.

        :returns: The updated PaymentInstance
        :rtype: twilio.rest.api.v2010.account.call.payment.PaymentInstance
        """
        return self._proxy.update(idempotency_key, status_callback, capture=capture, status=status, )

    def __repr__(self):
        """
        Provide a friendly representation

        :returns: Machine friendly representation
        :rtype: str
        """
        context = ' '.join('{}={}'.format(k, v) for k, v in self._solution.items())
        return '<Twilio.Api.V2010.PaymentInstance {}>'.format(context)

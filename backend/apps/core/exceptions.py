from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
import logging

logger = logging.getLogger(__name__)

def custom_exception_handler(exc, context):
    """
    Custom exception handler providing consistent JSON error structures.
    """
    response = exception_handler(exc, context)

    if response is not None:
        custom_data = {
            'success': False,
            'status_code': response.status_code,
            'message': 'An error occurred during request processing.',
            'errors': response.data
        }

        # Normalize message if detail or non_field_errors exists
        if isinstance(response.data, dict):
            if 'detail' in response.data:
                custom_data['message'] = str(response.data['detail'])
            elif 'non_field_errors' in response.data:
                custom_data['message'] = response.data['non_field_errors'][0] if response.data['non_field_errors'] else 'Validation error'
        elif isinstance(response.data, list) and response.data:
            custom_data['message'] = str(response.data[0])

        response.data = custom_data
    else:
        logger.error(f"Unhandled Exception: {str(exc)}", exc_info=True)
        response = Response({
            'success': False,
            'status_code': status.HTTP_500_INTERNAL_SERVER_ERROR,
            'message': 'Internal server error. The incident has been recorded.',
            'errors': None
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return response

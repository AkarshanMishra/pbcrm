import re
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _
from django.contrib.auth.hashers import check_password
import zxcvbn

class ComplexPasswordValidator:
    """
    Validates that the password satisfies enterprise complexity rules:
    - At least 12 characters
    - Contains at least 1 uppercase letter
    - Contains at least 1 lowercase letter
    - Contains at least 1 number
    - Contains at least 1 special symbol
    - Has acceptable zxcvbn entropy score (>= 3)
    """
    def __init__(self, min_length=12):
        self.min_length = min_length

    def validate(self, password, user=None):
        if len(password) < self.min_length:
            raise ValidationError(
                _(f"Password must be at least {self.min_length} characters long."),
                code='password_too_short'
            )
        if not re.search(r'[A-Z]', password):
            raise ValidationError(
                _("Password must contain at least one uppercase letter (A-Z)."),
                code='password_no_upper'
            )
        if not re.search(r'[a-z]', password):
            raise ValidationError(
                _("Password must contain at least one lowercase letter (a-z)."),
                code='password_no_lower'
            )
        if not re.search(r'[0-9]', password):
            raise ValidationError(
                _("Password must contain at least one digit (0-9)."),
                code='password_no_digit'
            )
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
            raise ValidationError(
                _("Password must contain at least one special character (!@#$%^&*...)."),
                code='password_no_symbol'
            )

        # zxcvbn entropy evaluation
        user_inputs = []
        if user:
            if getattr(user, 'email', None):
                user_inputs.append(user.email)
            if getattr(user, 'employee_code', None):
                user_inputs.append(user.employee_code)
                
        eval_result = zxcvbn.zxcvbn(password, user_inputs=user_inputs)
        if eval_result['score'] < 3:
            feedback = eval_result['feedback']['warning'] or "Password is too predictable or easily guessable."
            raise ValidationError(
                _(f"Weak password: {feedback}"),
                code='password_too_weak'
            )

    def get_help_text(self):
        return _(
            "Your password must contain at least 12 characters, including uppercase, "
            "lowercase, numbers, and special characters, and cannot be a common phrase."
        )


class PasswordHistoryValidator:
    """
    Prevents a user from reusing any of their last 5 previous passwords.
    """
    def __init__(self, history_limit=5):
        self.history_limit = history_limit

    def validate(self, password, user=None):
        if not user or not user.pk:
            return

        from .models import PasswordHistory
        past_passwords = PasswordHistory.objects.filter(user=user).order_by('-created_at')[:self.history_limit]
        for past_entry in past_passwords:
            if check_password(password, past_entry.password_hash):
                raise ValidationError(
                    _(f"You cannot reuse any of your last {self.history_limit} passwords."),
                    code='password_reused'
                )

    def get_help_text(self):
        return _(f"You cannot reuse your last {self.history_limit} passwords.")

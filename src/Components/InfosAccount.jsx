
function InfosAccount(props) {
    return (
        <div>
            {!props.loader &&
                props.accounts.length > 0 ?
                <div>
                <p>Your connected account is : {props.accounts[0]}</p>
                {props.balance && <p>You have {props.balance} ETH on your account.</p>}
                {props.balance < 0.06 && <p className="infos"></p>}
                </div>
                :
                <p>You are not connected with Metamask on this website.
                    Please connect with a compatible browser for Metamask, not on your phone.
                </p>
            }
        </div>
    )
}

export default InfosAccount;